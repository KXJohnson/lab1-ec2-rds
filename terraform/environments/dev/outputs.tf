# -----------------------------------------------------------------------------
# LAB1 Outputs
# Purpose:
# - Provide quick validation values for screenshots and grading
# - Avoid outputting sensitive values such as database password or secret contents
# -----------------------------------------------------------------------------

output "ec2_instance_id" {
  description = "LAB1 EC2 app server instance ID."
  value       = aws_instance.ec2_app.id
}

output "ec2_public_ip" {
  description = "Public IP address of the LAB1 EC2 app server."
  value       = aws_instance.ec2_app.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS name of the LAB1 EC2 app server."
  value       = aws_instance.ec2_app.public_dns
}

output "ec2_app_url" {
  description = "HTTP URL for the LAB1 app server."
  value       = "http://${aws_instance.ec2_app.public_ip}"
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint."
  value       = aws_db_instance.mysql.address
}

output "rds_identifier" {
  description = "RDS instance identifier."
  value       = aws_db_instance.mysql.identifier
}

output "rds_secret_name" {
  description = "AWS Secrets Manager secret name for RDS credentials."
  value       = aws_secretsmanager_secret.rds_credentials.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for LAB1 EC2 logs."
  value       = aws_cloudwatch_log_group.ec2_app.name
}

output "cloudwatch_alarm_name" {
  description = "CloudWatch alarm name for LAB1 app failure monitoring."
  value       = aws_cloudwatch_metric_alarm.ec2_app_failures.alarm_name
}

output "ec2_instance_profile_name" {
  description = "IAM instance profile attached to the LAB1 EC2 app server."
  value       = aws_iam_instance_profile.ec2_app_instance_profile.name
}

# -----------------------------------------------------------------------------
# LAB1 Bonus D Outputs
# -----------------------------------------------------------------------------

output "apex_url_https" {
  description = "HTTPS URL for the LAB1 apex domain."
  value       = "https://${var.domain_name}"
}

output "alb_logs_bucket_name" {
  description = "S3 bucket name for LAB1 ALB access logs."
  value       = aws_s3_bucket.alb_logs.bucket
}

output "alb_access_logs_prefix" {
  description = "S3 prefix for LAB1 ALB access logs."
  value       = var.alb_access_logs_prefix
}
