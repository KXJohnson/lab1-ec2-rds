variable "aws_region" {
  description = "AWS region where LAB1 resources will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "lab-rds-app"
}

variable "vpc_cidr" {
  description = "CIDR block for the LAB1 VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the LAB1 public subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_a_cidr" {
  description = "CIDR block for the LAB1 private subnet in Availability Zone A."
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_b_cidr" {
  description = "CIDR block for the LAB1 private subnet in Availability Zone B."
  type        = string
  default     = "10.0.3.0/24"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the LAB1 EC2 app server. Set as a sensitive Terraform variable in HCP Terraform."
  type        = string
  sensitive   = true
}

variable "app_port" {
  description = "Port used by the LAB1 web application."
  type        = number
  default     = 80
}

variable "db_identifier" {
  type    = string
  default = "lab-rds-app"
}

variable "db_name" {
  type    = string
  default = "notes"
}
variable "db_password" {
  description = "Sensitive RDS database password provided by HCP Terraform."
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "owner" {
  description = "Owner tag value for LAB1 resources."
  type        = string
}

variable "environment" {
  description = "Environment tag value for LAB1 resources."
  type        = string
}


variable "alarm_notification_email" {
  description = "Email address that receives CloudWatch alarm notifications through SNS"
  type        = string
  sensitive   = true
}

variable "secret_path" {
  type    = string
  default = "lab/rds/mysql"
}

variable "common_tags" {
  type = map(string)
  default = {
    Name        = "lab-rds-app"
    Environment = "lab"
    Project     = "Lab1"
  }
}

variable "public_subnet_b_cidr" {
  description = "CIDR block for the LAB1 second public subnet for the Bonus B ALB."
  type        = string
  default     = "10.0.4.0/24"
}

# -----------------------------------------------------------------------------
# LAB1 Bonus C - Route53 + ACM + HTTPS
# -----------------------------------------------------------------------------

variable "domain_name" {
  description = "Root domain name managed in Route53 for LAB1 Bonus C."
  type        = string
  default     = "kulturalintercessor.org"
}

variable "app_subdomain" {
  description = "Subdomain for the LAB1 app ALB."
  type        = string
  default     = "app"
}

# -----------------------------------------------------------------------------
# LAB1 Bonus D - Apex Route53 ALIAS + ALB Access Logs
# -----------------------------------------------------------------------------

variable "enable_alb_access_logs" {
  description = "Enable ALB access logging to S3."
  type        = bool
  default     = true
}

variable "alb_access_logs_prefix" {
  description = "S3 prefix for ALB access logs."
  type        = string
  default     = "alb-access-logs"
}
