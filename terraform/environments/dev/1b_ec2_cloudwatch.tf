# -----------------------------------------------------------------------------
# LAB1 EC2 + CloudWatch
# Purpose:
# - Launch a public EC2 app server in the LAB1 public subnet
# - Attach the IAM instance profile so EC2 can read Secrets Manager and write logs
# - Install CloudWatch Agent through user_data
# - Ship app/bootstrap logs into CloudWatch Logs
# - Create a CloudWatch alarm for app failure signals
# -----------------------------------------------------------------------------

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_cloudwatch_log_group" "ec2_app" {
  name              = local.cloudwatch_log_group
  retention_in_days = 14

  tags = merge(
    local.common_tags,
    {
      Name = local.cloudwatch_log_group
    }
  )
}

resource "aws_instance" "ec2_app" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_app_instance_profile.name
  associate_public_ip_address = true

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    dnf update -y
    dnf install -y amazon-cloudwatch-agent python3 python3-pip mariadb105

    mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
    mkdir -p /opt/lab1-app

    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCONFIG'
    {
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/cloud-init-output.log",
                "log_group_name": "${local.cloudwatch_log_group}",
                "log_stream_name": "{instance_id}/cloud-init-output",
                "timezone": "UTC"
              },
              {
                "file_path": "/var/log/messages",
                "log_group_name": "${local.cloudwatch_log_group}",
                "log_stream_name": "{instance_id}/messages",
                "timezone": "UTC"
              }
            ]
          }
        }
      }
    }
    CWCONFIG

    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config \
      -m ec2 \
      -s \
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

    cat > /opt/lab1-app/app.py <<'PYAPP'
    from http.server import BaseHTTPRequestHandler, HTTPServer
    import datetime
    import json
    import subprocess

    SECRET_NAME = "${local.rds_secret_name}"
    REGION = "${local.region}"
    DB_HOST = "${aws_db_instance.mysql.address}"
    DB_NAME = "${var.db_name}"

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            now = datetime.datetime.utcnow().isoformat()
            status = {
                "status": "ok",
                "lab": "LAB1",
                "service": "ec2-to-rds-notes-app",
                "time_utc": now,
                "secret_name": SECRET_NAME,
                "region": REGION,
                "db_host": DB_HOST,
                "db_name": DB_NAME
            }

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(status, indent=2).encode())

        def log_message(self, format, *args):
            print("LAB1_APP_LOG " + format % args)

    if __name__ == "__main__":
        print("LAB1 app starting on port 80")
        HTTPServer(("0.0.0.0", 80), Handler).serve_forever()
    PYAPP

    cat > /etc/systemd/system/lab1-app.service <<'SERVICE'
    [Unit]
    Description=LAB1 EC2 to RDS Notes App
    After=network-online.target
    Wants=network-online.target

    [Service]
    Type=simple
    ExecStart=/usr/bin/python3 /opt/lab1-app/app.py
    Restart=always
    RestartSec=5
    StandardOutput=journal
    StandardError=journal

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable lab1-app
    systemctl start lab1-app
  EOF

  depends_on = [
    aws_cloudwatch_log_group.ec2_app,
    aws_iam_role_policy_attachment.ec2_app_policy_attachment,
    aws_db_instance.mysql,
    aws_secretsmanager_secret_version.rds_credentials
  ]

  tags = merge(
    local.common_tags,
    {
      Name = local.ec2_name
    }
  )
}

resource "aws_cloudwatch_log_metric_filter" "ec2_app_failures" {
  name           = "${local.name_prefix}-app-failure-filter"
  log_group_name = aws_cloudwatch_log_group.ec2_app.name

  pattern = "?ERROR ?Error ?error ?FAILED ?Failed ?failed ?Exception ?exception"

  metric_transformation {
    name      = "${local.name_prefix}-app-failures"
    namespace = "LAB1/EC2App"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_app_failures" {
  alarm_name          = local.cloudwatch_alarm_name
  alarm_description   = "Triggers when LAB1 EC2 app failure messages exceed the threshold."
  namespace           = "LAB1/EC2App"
  metric_name         = aws_cloudwatch_log_metric_filter.ec2_app_failures.metric_transformation[0].name
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  tags = merge(
    local.common_tags,
    {
      Name = local.cloudwatch_alarm_name
    }
  )
}