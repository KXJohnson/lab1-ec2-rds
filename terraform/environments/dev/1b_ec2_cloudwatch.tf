# -----------------------------------------------------------------------------
# LAB1 EC2 + CloudWatch
# Purpose:
# - Launch a public EC2 app server in the LAB1 public subnet
# - Attach the IAM instance profile so EC2 can read Secrets Manager and write logs
# - Install CloudWatch Agent through user_data
# - Ship app/bootstrap logs into CloudWatch Logs
# - Run a Python app that proves:
#   Browser -> EC2 -> IAM instance profile -> Secrets Manager -> RDS MySQL
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

  # Important:
  # Changing user_data will replace the EC2 instance so the new bootstrap script runs.
  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    dnf update -y
    dnf install -y amazon-cloudwatch-agent python3 python3-pip mariadb105

    mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
    mkdir -p /opt/lab1-app
    touch /var/log/lab1-app.log
    chmod 644 /var/log/lab1-app.log

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
                "file_path": "/var/log/lab1-app.log",
                "log_group_name": "${local.cloudwatch_log_group}",
                "log_stream_name": "{instance_id}/lab1-app",
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

    python3 -m venv /opt/lab1-app/venv
    /opt/lab1-app/venv/bin/python -m pip install --upgrade pip
    /opt/lab1-app/venv/bin/pip install boto3 PyMySQL

    cat > /opt/lab1-app/app.py <<'PYAPP'
    from http.server import BaseHTTPRequestHandler, HTTPServer
    import datetime
    import json
    import logging
    import traceback

    import boto3
    import pymysql

    SECRET_NAME = "${local.rds_secret_name}"
    REGION = "${local.region}"
    DB_HOST = "${aws_db_instance.mysql.address}"
    DB_NAME = "${var.db_name}"
    DB_PORT = 3306
    TABLE_NAME = "notes"

    logging.basicConfig(
        filename="/var/log/lab1-app.log",
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s"
    )

    def read_secret():
        client = boto3.client("secretsmanager", region_name=REGION)
        response = client.get_secret_value(SecretId=SECRET_NAME)
        secret_string = response["SecretString"]
        secret = json.loads(secret_string)

        username = secret.get("username")
        password = secret.get("password")

        if not username or not password:
            raise ValueError("Secret is missing required username/password fields.")

        return username, password

    def validate_database(username, password):
        connection = pymysql.connect(
            host=DB_HOST,
            user=username,
            password=password,
            database=DB_NAME,
            port=DB_PORT,
            connect_timeout=5,
            autocommit=True,
            cursorclass=pymysql.cursors.DictCursor
        )

        with connection:
            with connection.cursor() as cursor:
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS notes (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        content VARCHAR(255) NOT NULL,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)

                cursor.execute("SELECT DATABASE() AS database_name")
                database_result = cursor.fetchone()

                cursor.execute("SHOW TABLES LIKE %s", (TABLE_NAME,))
                table_result = cursor.fetchone()

        if not database_result or database_result["database_name"] != DB_NAME:
            raise RuntimeError("Database validation failed.")

        if not table_result:
            raise RuntimeError("Notes table validation failed.")

        return True

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            now = datetime.datetime.utcnow().isoformat() + "Z"

            result = {
                "lab": "LAB1",
                "service": "ec2-to-rds-notes-app",
                "time_utc": now,
                "secret_name": SECRET_NAME,
                "secret_read": "pending",
                "database_connection": "pending",
                "database": DB_NAME,
                "table": TABLE_NAME
            }

            status_code = 200

            try:
                username, password = read_secret()
                result["secret_read"] = "ok"

                validate_database(username, password)
                result["database_connection"] = "ok"

                logging.info(
                    "LAB1_APP_OK secret_read=ok database_connection=ok database=%s table=%s",
                    DB_NAME,
                    TABLE_NAME
                )

            except Exception as error:
                status_code = 500
                result["status"] = "error"
                result["error_type"] = type(error).__name__
                result["error_message"] = str(error)

                logging.error(
                    "LAB1_APP_ERROR secret_or_db_validation_failed error_type=%s error_message=%s traceback=%s",
                    type(error).__name__,
                    str(error),
                    traceback.format_exc()
                )

            self.send_response(status_code)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(result, indent=2).encode())

        def log_message(self, format, *args):
            logging.info("HTTP_REQUEST " + format % args)

    if __name__ == "__main__":
        logging.info("LAB1 app starting on port 80")
        HTTPServer(("0.0.0.0", 80), Handler).serve_forever()
    PYAPP

    cat > /etc/systemd/system/lab1-app.service <<'SERVICE'
    [Unit]
    Description=LAB1 EC2 to RDS Notes App
    After=network-online.target
    Wants=network-online.target

    [Service]
    Type=simple
    ExecStart=/opt/lab1-app/venv/bin/python /opt/lab1-app/app.py
    Restart=always
    RestartSec=5
    StandardOutput=append:/var/log/lab1-app.log
    StandardError=append:/var/log/lab1-app.log

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable lab1-app
    systemctl restart lab1-app
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

  # Captures explicit application failures for LAB1 incident-response proof.
  pattern = "?LAB1_APP_ERROR ?ERROR ?Error ?error ?FAILED ?Failed ?failed ?Exception ?exception"

  metric_transformation {
    name      = "${local.name_prefix}-app-failures"
    namespace = "LAB1/EC2App"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_app_failures" {
  alarm_name        = local.cloudwatch_alarm_name
  alarm_description = "Triggers when LAB1 EC2 app failure messages exceed the threshold."

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