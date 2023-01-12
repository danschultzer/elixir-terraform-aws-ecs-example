terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.46"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      CreatedBy   = "terraform"
      Workspace   = terraform.workspace
      Project     = split("/", var.github_repository)[1]
      Environment = var.environment
    }
  }
}
