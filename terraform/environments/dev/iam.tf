# -----------------------------------------------------------------------------
# LAB1 IAM
# Purpose:
# - Allow the EC2 app server to read the RDS credentials from AWS Secrets Manager
# - Allow the EC2 app server to write logs to CloudWatch Logs
# - Attach an instance profile to the EC2 instance for grading screenshots
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  ec2_iam_role_name         = "${local.name_prefix}-ec2-role"
  ec2_iam_policy_name       = "${local.name_prefix}-ec2-policy"
  ec2_instance_profile_name = "${local.name_prefix}-ec2-instance-profile"

  rds_secret_arn_pattern = "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${local.rds_secret_name}-*"
}

resource "aws_iam_role" "ec2_app_role" {
  name = local.ec2_iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = local.ec2_iam_role_name
    }
  )
}

resource "aws_iam_policy" "ec2_app_policy" {
  name        = local.ec2_iam_policy_name
  description = "Allows LAB1 EC2 app server to read RDS credentials and write CloudWatch logs."

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadRdsCredentialsFromSecretsManager"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]

        Resource = local.rds_secret_arn_pattern
      },
      {
        Sid    = "ReadRdsParametersFromSsm"
        Effect = "Allow"

        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]

        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/lab/db/*"

      },
      {
        Sid    = "WriteCloudWatchLogs"
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ]

        Resource = "*"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = local.ec2_iam_policy_name
    }
  )
}

resource "aws_iam_role_policy_attachment" "ec2_app_policy_attachment" {
  role       = aws_iam_role.ec2_app_role.name
  policy_arn = aws_iam_policy.ec2_app_policy.arn
}


resource "aws_iam_role_policy_attachment" "ec2_ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "ec2_app_instance_profile" {
  name = local.ec2_instance_profile_name
  role = aws_iam_role.ec2_app_role.name

  tags = merge(
    local.common_tags,
    {
      Name = local.ec2_instance_profile_name
    }
  )
}