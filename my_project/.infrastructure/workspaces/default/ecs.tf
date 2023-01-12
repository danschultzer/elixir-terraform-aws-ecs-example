locals {
  ecs_container_name = local.name
}

# Generate a random secret key base
resource "random_password" "secret_key_base" {
  length  = 64
  special = true
  numeric = true
  upper   = true
  lower   = true
}

# Create a security group for the load balancer
resource "aws_security_group" "lb" {
  name        = "${local.name}-load-balancer"
  description = "Controls access to the load balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Create a security group for the app containers
resource "aws_security_group" "app" {
  name        = "${local.name}-application"
  description = "Allow access from load balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Application load balancer
resource "aws_lb" "this" {
  name               = local.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = module.vpc.public_subnets
}

# Target group for the load balancer
resource "aws_lb_target_group" "this" {
  name        = local.name
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    enabled = true
    path    = "/"
    matcher = "200"
  }
}

# Associate the load balancer with the target group via a listener
resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# Create the ECS cluster 
resource "aws_ecs_cluster" "this" {
  name = local.name
}

# Create the ECS task definition
resource "aws_ecs_task_definition" "app" {
  family                   = aws_ecs_cluster.this.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048

  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task_app.arn

  container_definitions = jsonencode([
    {
      essential = true
      image     = "${aws_ecr_repository.this.repository_url}:latest"
      name      = local.ecs_container_name

      portMappings = [
        {
          containerPort = 4000
          hostPort      = 4000
          protocol      = "tcp"
        }
      ]

      environment = [
        # The following config can be used if you don't want to specify a
        # domain and just use the whatever DNS hostname the load balancer has.
        # In a Phoenix app you could configure the url at runtime with:
        #
        # uri = URI.parse(System.get_env("MY_APP_HOST", "example.com"))
        #
        # config :my_app_web, MyAppWeb.Endpoint,
        #   url: [host: uri.host, port: uri.port || 81],
        #
        # {
        #  name  = "MY_APP_HOST"
        #  value = aws_lb.this.dns_name
        # },
        {
          name  = "SECRET_KEY_BASE"
          value = random_password.secret_key_base.result
        }
      ]
    }
  ])
}

# Create the ECS service
resource "aws_ecs_service" "app" {
  name            = local.name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = local.ecs_container_name
    container_port   = 4000
  }

  network_configuration {
    security_groups  = [aws_security_group.app.id]
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
  }
}

# ECS execution and task roles
data "aws_iam_policy_document" "assume_ecs" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }
  }
}
resource "aws_iam_policy" "ecs_task_execution" {
  name   = "${local.name}-ecs-task-execution"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [  
    {
        "Effect": "Allow",
        "Action": [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "ecr:GetAuthorizationToken"
        ],
        "Resource": "*"
    }
  ]
}
EOF
}
resource "aws_iam_role" "ecs_task_execution" {
  name               = "${local.name}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ecs.json
}
resource "aws_iam_role" "ecs_task_app" {
  name               = "${local.name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ecs.json
}
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecs_task_execution.arn
}
