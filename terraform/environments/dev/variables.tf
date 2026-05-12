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
