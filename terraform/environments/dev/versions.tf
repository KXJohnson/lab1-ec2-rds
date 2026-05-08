terraform {
  required_version = ">= 1.11.0"

  cloud {
    organization = "ragejournal0k"

    workspaces {
      name = "lab1-ec2-rds"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }

    #vault = {
    #  source  = "hashicorp/vault"
    #  version = ">= 5.0"
  }
}
#}
