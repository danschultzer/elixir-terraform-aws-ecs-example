resource "aws_ecr_repository" "this" {
  name = var.github_repository
}
