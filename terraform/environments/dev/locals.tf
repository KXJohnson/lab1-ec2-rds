locals {
  project         = "lab1"
  environment     = "dev"
  owner           = "kxjohnson"
  region          = "us-east-1"
  rds_secret_name = "lab/rds/mysql"
  db_username     = "admin"

  name_prefix = "${local.project}-${local.environment}"

  common_tags = {
    Project     = local.project
    Environment = local.environment
    Owner       = local.owner
    ManagedBy   = "terraform"
    Lab         = "LAB1"
  }

  # Naming contract
  vpc_name              = "${local.name_prefix}-vpc"
  public_subnet_name    = "${local.name_prefix}-public-subnet"
  private_subnet_name   = "${local.name_prefix}-private-subnet"
  ec2_name              = "${local.name_prefix}-ec2-app"
  ec2_sg_name           = "${local.name_prefix}-ec2-sg"
  rds_sg_name           = "${local.name_prefix}-rds-sg"
  rds_identifier        = "${local.name_prefix}-mysql"
  db_subnet_group_name  = "${local.name_prefix}-db-subnet-group"
  secret_name           = "${local.name_prefix}/rds/mysql"
  iam_role_name         = "${local.name_prefix}-ec2-role"
  instance_profile_name = "${local.name_prefix}-ec2-instance-profile"
  cloudwatch_log_group  = "/aws/ec2/${local.name_prefix}-app"
  cloudwatch_alarm_name = "${local.name_prefix}-app-failure-alarm"
  sns_topic_name        = "${local.name_prefix}-app-alerts"
}
