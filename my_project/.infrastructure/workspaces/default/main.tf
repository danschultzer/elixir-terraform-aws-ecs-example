locals {
  name                   = "${replace(split("/", var.github_repository)[1], "_", "-")}-${var.environment}"
  vpc_availability_zones = var.vpc_availability_zones == null ? formatlist("${var.aws_region}%s", ["a", "b"]) : var.vpc_availability_zones
}

# Create the VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = var.vpc_cidr

  azs             = local.vpc_availability_zones
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_dns_hostnames = true
  enable_dns_support   = true
}
