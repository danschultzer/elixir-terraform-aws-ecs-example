variable "github_repository" {
  description = "Your Github repository"
  type        = string
}

variable "aws_region" {
  description = "The AWS region"
  type        = string
}

variable "aws_account_id" {
  description = "The AWS account ID"
  type        = string
}

variable "environment" {
  description = "The project environment"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "CIDR for the VPC"
}

variable "vpc_public_subnets" {
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
  description = "Public subnets for the VPC"
}

variable "vpc_private_subnets" {
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  description = "Private subnets for the VPC"
}

variable "vpc_availability_zones" {
  default     = null
  description = "Availability zones for subnets"
}

variable "rds_db_username" {
  description = "The RDS database username"
  type        = string
  default     = "dbuser"
}

variable "rds_db_port" {
  description = "The RDS database port"
  type        = number
  default     = null
}

variable "rds_instance_type" {
  default     = "db.m6g.large"
  description = "RDS instance type"
}

variable "rds_encrypt_at_rest" {
  default     = false
  description = "DB encryption setting"
}

