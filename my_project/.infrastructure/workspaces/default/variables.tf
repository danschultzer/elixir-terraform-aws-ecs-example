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
