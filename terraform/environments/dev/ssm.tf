# -----------------------------------------------------------------------------
# LAB1 Systems Manager Parameter Store
# Purpose:
# - Store non-secret database configuration values required by Lab 1b
# - Support incident-response recovery without guessing or redeploying EC2
# - Keep credentials in Secrets Manager while storing configuration in SSM
# -----------------------------------------------------------------------------

resource "aws_ssm_parameter" "db_endpoint" {
  name        = "/lab/db/endpoint"
  description = "LAB1 RDS endpoint used by the EC2 notes app."
  type        = "String"
  value       = aws_db_instance.mysql.address

  tags = merge(
    local.common_tags,
    {
      Name = "/lab/db/endpoint"
    }
  )
}

resource "aws_ssm_parameter" "db_port" {
  name        = "/lab/db/port"
  description = "LAB1 RDS port used by the EC2 notes app."
  type        = "String"
  value       = tostring(aws_db_instance.mysql.port)

  tags = merge(
    local.common_tags,
    {
      Name = "/lab/db/port"
    }
  )
}

resource "aws_ssm_parameter" "db_name" {
  name        = "/lab/db/name"
  description = "LAB1 database name used by the EC2 notes app."
  type        = "String"
  value       = var.db_name

  tags = merge(
    local.common_tags,
    {
      Name = "/lab/db/name"
    }
  )
}