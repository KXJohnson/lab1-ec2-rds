# -----------------------------------------------------------------------------
# LAB1 Bonus G - Bedrock-powered Incident Reporter
# Purpose:
# - Subscribe a Lambda function to the existing LAB1 alarm SNS topic
# - Collect CloudWatch Logs Insights evidence from app and WAF log groups
# - Read recovery context from SSM Parameter Store and Secrets Manager
# - Invoke Amazon Bedrock to generate a Markdown incident report
# - Store the report in S3
# - Publish a report-ready notification to a separate SNS topic
# -----------------------------------------------------------------------------

data "archive_file" "incident_reporter_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/incident_reporter"
  output_path = "${path.module}/lambda/incident_reporter.zip"
}

resource "aws_s3_bucket" "incident_reports" {
  bucket        = "${local.name_prefix}-incident-reports-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-incident-reports"
      Lab  = "LAB1-Bonus-G"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "incident_reports" {
  bucket = aws_s3_bucket.incident_reports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "incident_reports" {
  bucket = aws_s3_bucket.incident_reports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_sns_topic" "incident_report_ready" {
  name = "${local.name_prefix}-incident-report-ready"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-incident-report-ready"
      Lab  = "LAB1-Bonus-G"
    }
  )
}

resource "aws_iam_role" "incident_reporter_lambda" {
  name = "${local.name_prefix}-incident-reporter-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-incident-reporter-lambda-role"
      Lab  = "LAB1-Bonus-G"
    }
  )
}

resource "aws_iam_role_policy" "incident_reporter_lambda" {
  name = "${local.name_prefix}-incident-reporter-lambda-policy"
  role = aws_iam_role.incident_reporter_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteLambdaLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Sid    = "RunLogsInsightsQueries"
        Effect = "Allow"
        Action = [
          "logs:StartQuery",
          "logs:GetQueryResults",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Sid    = "ReadRecoveryContext"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.rds_credentials.arn,
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/lab/db/*"
        ]
      },
      {
        Sid    = "WriteIncidentReports"
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.incident_reports.arn}/incident-reports/*"
      },
      {
        Sid    = "PublishReportReady"
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.incident_report_ready.arn
      },

      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = [
          "arn:aws:bedrock:${var.aws_region}::foundation-model/*",
          "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:inference-profile/*",
          "arn:aws:bedrock:*:${data.aws_caller_identity.current.account_id}:inference-profile/*"
        ]
      }
    ]
  })

}

resource "aws_lambda_function" "incident_reporter" {
  function_name = "${local.name_prefix}-incident-reporter"
  role          = aws_iam_role.incident_reporter_lambda.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 180
  memory_size   = 256

  filename         = data.archive_file.incident_reporter_zip.output_path
  source_code_hash = data.archive_file.incident_reporter_zip.output_base64sha256

  environment {
    variables = {
      APP_LOG_GROUP    = aws_cloudwatch_log_group.ec2_app.name
      WAF_LOG_GROUP    = aws_cloudwatch_log_group.waf_logs.name
      REPORT_BUCKET    = aws_s3_bucket.incident_reports.bucket
      REPORT_TOPIC_ARN = aws_sns_topic.incident_report_ready.arn
      SECRET_ID        = aws_secretsmanager_secret.rds_credentials.name
      BEDROCK_MODEL_ID = "us.anthropic.claude-haiku-4-5-20251001-v1:0"
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-incident-reporter"
      Lab  = "LAB1-Bonus-G"
    }
  )
}

resource "aws_lambda_permission" "allow_alarm_sns" {
  statement_id  = "AllowExecutionFromAlarmSns"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.incident_reporter.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.app_alerts.arn
}

resource "aws_sns_topic_subscription" "alarm_to_incident_reporter_lambda" {
  topic_arn = aws_sns_topic.app_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.incident_reporter.arn
}

output "bonus_g_incident_report_bucket" {
  description = "S3 bucket where Bonus G incident reports are written."
  value       = aws_s3_bucket.incident_reports.bucket
}

output "bonus_g_incident_report_ready_topic_arn" {
  description = "SNS topic where the IncidentReporter Lambda publishes report-ready messages."
  value       = aws_sns_topic.incident_report_ready.arn
}

output "bonus_g_incident_reporter_lambda_name" {
  description = "Name of the Bonus G IncidentReporter Lambda function."
  value       = aws_lambda_function.incident_reporter.function_name
}
