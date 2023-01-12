resource "aws_codedeploy_app" "this" {
  name             = local.name
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "this" {
  app_name               = aws_codedeploy_app.this.name
  deployment_group_name  = local.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = aws_iam_role.code_deploy_ecs.arn

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.this.name
    service_name = aws_ecs_service.app1.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.app1.arn]
      }

      dynamic "target_group" {
        for_each = aws_lb_target_group.app1

        content {
          name = target_group.value.name
        }
      }
    }
  }
}

data "aws_iam_policy" "limited_code_deploy_default" {
  name = "AWSCodeDeployRoleForECSLimited"
}

resource "aws_iam_role" "code_deploy_ecs" {
  name               = "${local.name}-code-deploy-ecs"
  assume_role_policy = data.aws_iam_policy_document.assume_code_deploy.json
}

resource "aws_iam_role_policy" "pass_ecs_roles" {
  role   = aws_iam_role.code_deploy_ecs.id
  policy = data.aws_iam_policy_document.code_deploy_ecs.json
}

resource "aws_iam_role_policy_attachment" "limited_code_deploy_default" {
  role       = aws_iam_role.code_deploy_ecs.id
  policy_arn = data.aws_iam_policy.limited_code_deploy_default.arn
}

data "aws_iam_policy_document" "assume_code_deploy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
  }
}

data "aws_iam_policy_document" "code_deploy_ecs" {
  statement {
    sid     = "PassRolesInTaskDefinition"
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.ecs_task_execution.arn,
      aws_iam_role.ecs_task_app.arn
    ]
  }
}
