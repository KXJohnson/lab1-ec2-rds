provider "aws" {
  region = var.aws_region
}

provider "vault" {
  address = var.vault_addr
}
