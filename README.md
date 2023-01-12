# Elixir Terraform AWS ECS Example

There are some resources on terraform and/or ECS setup with Elixir, but all were missing some pieces I needed. Either they were outdated, or incomplete for my use case. So I've created this repo to show how you can set up a complete production-ready ECS setup with terraform.

## Features

- Github Actions builds and pushes to ECR
- ECS with rolling deployment
- ECS with blue-green deployment using CodeDeploy
- Github Actions triggers deployment
- Monolithic support with multiple ports
- Secrets in Secrets Manager
- CloudWatch for logging
- RDS postgres instance
- Elixir clustering

This includes the necessary network and permissions configuration.

## Caveat for CodeDeploy and multiple ports

One caveat to know is that AWS doesn't support multiple target groups for CodeDeploy controller. So for blue-green deployment to work with multiple ports on the instance it's necessary to set up separate ECS services for each port.

If you are not going to use blue-green deployment then you can just add a second `load_balance` on the `aws_ecs_service`.

## Prerequisites

It's expected that you already have an Elixir app dockerized with an `entrypoint.sh` bash script. See [`my_project/README.md`](my_project/README.md) for details.

## Go by commits

To make it easier to understand what each part does you should follow the commit history. It'll go step-by-step for each feature.
