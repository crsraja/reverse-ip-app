#provider "aws" {
#  region = local.config["aws_region"]
#}

locals {
  config = yamldecode(file("${path.module}/variables.yaml"))
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = local.config["vpc_cidr"]
}

# Subnet
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.config["subnet_cidr"]
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

# Security Group
resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.main.id
  name   = "ecs-security-group"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "ecs" {
  name = local.config["ecs_cluster_name"]
}

# ECR Repository
resource "aws_ecr_repository" "ecr" {
  name = local.config["ecr_repository_name"]
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = "ECSTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy_attachment" "ecs_task_execution_policy_attach" {
  name      = "ecs_task_execution_policy_attach"
  roles      = [aws_iam_role.ecs_task_execution.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "task" {
  family                   = "app-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  network_mode             = "awsvpc"
  container_definitions = jsonencode([{
    name      = "app"
    image     = "${aws_ecr_repository.ecr.repository_url}:latest"
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}

resource "aws_iam_role" "codebuild" {
  name = "CodeBuildServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
    
}

data "aws_iam_policy_document" "codebuild" {
  statement {
    sid = "SSOCodebuildAllow"

    actions = [
      "s3:*",
      "kms:*",
      "ssm:*",
      "secretmanager:*",

    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "*",
    ]
  }

}


resource "aws_iam_role_policy_attachment" "codebuild_policy" {
  role       = aws_iam_role.codebuild.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
}

output "ecs_cluster_name" {
  description = "ECS Cluster Name"
  value       = aws_ecs_cluster.ecs.name
}

output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = aws_ecr_repository.ecr.repository_url
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = aws_subnet.subnet1.id
}

output "ci_cd_role_arn" {
  description = "IAM Role for CI/CD Pipeline"
  value       = aws_iam_role.codebuild.arn
}

output "debug_yaml" {
  value = local.config
}

resource "aws_codebuild_project" "codebuild" {
  name          = "reverse-ip-build"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = "5"

  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image          = "aws/codebuild/standard:5.0"
    type           = "LINUX_CONTAINER"
    privileged_mode = true
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.config["aws_account_id"]
    } 
    environment_variable {
      name  = "AWS_REGION"
      value = local.config["aws_region"]
    }
  }

  source {
    type      = "GITHUB"
    location  = "${local.config["github_repo"]}.git"
    buildspec = "buildspec.yml"
  }

}
