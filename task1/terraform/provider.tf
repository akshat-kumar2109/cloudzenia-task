terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.94.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn = var.role_arn
  }
}