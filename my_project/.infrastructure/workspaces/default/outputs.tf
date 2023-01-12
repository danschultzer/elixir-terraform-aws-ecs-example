output "github_actions-AWS_REGION" {
  value       = var.aws_region
  description = "The AWS region - set this as AWS_REGION in the GHA variables"
}

output "github_actions-AWS_ECR_REPO" {
  value       = aws_ecr_repository.this.name
  description = "The ECR repo path - set this as AWS_ECR_REPO in the GHA variables"
}

output "github_actions-AWS_BUILD_ROLE" {
  value       = aws_iam_role.github_actions_ecr.arn
  description = "The ARN of the role that can be assumed by GHA to push images to ECR - set this as AWS_BUILD_ROLE in the GHA variables"
}
