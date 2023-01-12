locals {
  ecr_name = replace(aws_ecr_repository.this.name, "/", "-")
  ecs_name = aws_ecs_cluster.this.name
}

resource "aws_iam_role" "github_actions_ecr" {
  name               = "github-actions-ecr-${local.ecr_name}"
  description        = "Allow for github actions to push builds to the ${aws_ecr_repository.this.name} ECR"
  assume_role_policy = data.aws_iam_policy_document.github_actions_oidc.json
  inline_policy {
    name   = "${local.ecr_name}-ecr"
    policy = data.aws_iam_policy_document.github_actions_ecr.json
  }
}

data "aws_iam_policy_document" "github_actions_ecr" {
  statement {
    sid = "RepoReadWriteAccess"
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [
      aws_ecr_repository.this.arn
    ]
  }

  statement {
    sid       = "GetAuthorizationToken"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # The thumbprint will change occasionally. This thumbprint was picked from the blog post:
  # https://github.blog/changelog/2022-01-13-github-actions-update-on-oidc-based-deployments-to-aws/
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_actions_oidc" {
  statement {
    sid     = "GithubActionsRepoAssume"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"

      values = ["repo:${var.github_repository}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions_ecs" {
  name               = "github-actions-ecs-${local.ecs_name}"
  description        = "Allow for github actions to deploy to ${local.ecs_name} ECS"
  assume_role_policy = data.aws_iam_policy_document.github_actions_oidc.json
  inline_policy {
    name   = "${local.ecs_name}-ecs"
    policy = data.aws_iam_policy_document.github_actions_ecs.json
  }
}

data "aws_iam_policy_document" "github_actions_ecs" {
  statement {
    sid    = "RegisterTaskDefinition"
    effect = "Allow"
    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition"
    ]
    resources = ["*"]
  }
  statement {
    sid     = "PassRolesInTaskDefinition"
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.ecs_task_app.arn,
      aws_iam_role.ecs_task_execution.arn
    ]
  }
  statement {
    sid    = "DeployService"
    effect = "Allow"
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices"
    ]
    resources = [aws_ecs_service.app.id]
  }
}
