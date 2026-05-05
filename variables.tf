variable "project_name" {
  type    = string
  default = "lab-rds-app"
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
