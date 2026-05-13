# -----------------------------------------------------------------------------
# LAB1 Secrets Manager
# Purpose:
# - Create the runtime secret path for RDS credentials
# - Store the database connection values for the EC2 app server
# - Keep the sensitive database password out of GitHub, Terraform output,
#   Terraform plan files, and Terraform state by using write-only arguments
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = local.rds_secret_name
  description = "LAB1 RDS MySQL credentials for EC2 app server runtime access."

  recovery_window_in_days = 0

  tags = merge(
    local.common_tags,
    {
      Name = local.rds_secret_name
    }
  )
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id

  secret_string_wo = jsonencode({
    username = local.db_username
    password = var.db_password
    engine   = "mysql"
    port     = 3306
  })

  secret_string_wo_version = 1
}
