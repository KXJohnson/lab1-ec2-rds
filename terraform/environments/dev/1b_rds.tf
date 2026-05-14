# -----------------------------------------------------------------------------
# LAB1 RDS
#
# Purpose:
# - Create the private RDS MySQL database for the LAB1 Notes application
# - Place RDS in private subnets only
# - Attach the RDS security group that allows MySQL only from the EC2 app SG
# - Use the HCP Terraform sensitive + ephemeral db_password variable
# - Use AWS provider write-only password arguments so the DB password is not
#   stored in Terraform plan or state
# -----------------------------------------------------------------------------

resource "aws_db_subnet_group" "rds" {
  name = local.db_subnet_group_name

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = merge(
    local.common_tags,
    {
      Name = local.db_subnet_group_name
    }
  )
}

resource "aws_db_instance" "mysql" {
  identifier = local.rds_identifier

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = local.db_username

  password_wo         = var.db_password
  password_wo_version = 1

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.db.id]

  publicly_accessible = false
  multi_az            = false

  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true

  auto_minor_version_upgrade = true
  apply_immediately          = true

  tags = merge(
    local.common_tags,
    {
      Name = local.rds_identifier
    }
  )
}
