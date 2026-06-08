# -----------------------------------------------------------------------------
# LAB1C Bonus A: VPC Endpoints for Private EC2 Operations
# Purpose:
# - Prepare the environment for an EC2 instance with no public IP.
# - Allow SSM Session Manager access without SSH/public exposure.
# - Allow private access to CloudWatch Logs and Secrets Manager.
# - Add S3 gateway endpoint for private S3 access from private route tables.
# -----------------------------------------------------------------------------

resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.name_prefix}-vpc-endpoints-sg"
  description = "Security group for LAB1 interface VPC endpoints"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-vpc-endpoints-sg"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoints_https_from_app" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  description                  = "Allow HTTPS from LAB1 EC2 app server to VPC endpoints"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}

resource "aws_vpc_security_group_egress_rule" "vpc_endpoints_all_outbound" {
  security_group_id = aws_security_group.vpc_endpoints.id
  description       = "Allow all outbound traffic from VPC endpoints security group"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${local.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${local.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssmmessages-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${local.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ec2messages-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${local.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-logs-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${local.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-secretsmanager-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${local.region}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-kms-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${local.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-s3-gateway-endpoint"
    }
  )
}
