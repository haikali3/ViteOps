provider "aws" {
  region = "ap-southeast-1"
}

# ECR Repository already exist in AWS
data "aws_ecr_repository" "repo" {
  name = "haikali3/viteops"
}

# Data blocks for existing S3 buckets
resource "aws_s3_bucket" "input_bucket" {
  bucket = "s3-viteops-input"
}

resource "aws_s3_bucket" "output_bucket" {
  bucket = "s3-viteops-output"
}

# Batch Job

# IAM Role for Fargate Task
resource "aws_iam_role" "fargate_task_execution_role" {
  name = "fargate_task_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_access_policy" {
  name = "s3_access_policy"
  role = aws_iam_role.fargate_task_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = ["s3:GetObject", "s3:PutObject"],
        Effect = "Allow",
        Resource = [
          "arn:aws:s3:::s3-viteops-input/*",
          "arn:aws:s3:::s3-viteops-output/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "fargate_task_execution_role_policy" {
  role       = aws_iam_role.fargate_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Fargate Task Definition
resource "aws_ecs_task_definition" "fargate_task" {
  family                   = "fargate-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.fargate_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "fargate-container"
      image     = data.aws_ecr_repository.repo.repository_url
      essential = true
      environment = [
        {
          name  = "INPUT_BUCKET",
          value = "s3-viteops-input"
        },
        {
          name  = "OUTPUT_BUCKET",
          value = "s3-viteops-output"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/fargate-task"
          "awslogs-region"        = "ap-southeast-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# ECS Cluster
resource "aws_ecs_cluster" "fargate_cluster" {
  name = "fargate-cluster"
}

# ECS Service
resource "aws_ecs_service" "fargate_service" {
  name            = "fargate-service"
  cluster         = aws_ecs_cluster.fargate_cluster.id
  task_definition = aws_ecs_task_definition.fargate_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = ["subnet-08cf0225585ba0ca5"]
    security_groups = ["sg-010b7b0b62f7b3b2c"]
  }
}

# IAM Role for CloudWatch Events to trigger ECS
resource "aws_iam_role" "cloudwatch_events_role" {
  name = "cloudwatch_events_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_events_role_policy" {
  role       = aws_iam_role.cloudwatch_events_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}


# CloudWatch Event Rule for ECR image push
resource "aws_cloudwatch_event_rule" "ecr_image_push_rule" {
  name        = "ecr_image_push_rule"
  description = "Trigger ECS task when a new image is pushed to ECR"
  event_pattern = jsonencode({
    "source" : ["aws.ecr"],
    "detail-type" : ["ECR Image Action"],
    "detail" : {
      "action-type" : ["PUSH"],
      "repository-name" : ["haikali3/viteops"]
    }
  })
}

# CloudWatch Event Target to trigger ECS task
resource "aws_cloudwatch_event_target" "ecs_target" {
  rule      = aws_cloudwatch_event_rule.ecr_image_push_rule.name
  target_id = "ecs-task"
  arn       = aws_ecs_cluster.fargate_cluster.arn
  role_arn  = aws_iam_role.cloudwatch_events_role.arn
  ecs_target {
    task_definition_arn = aws_ecs_task_definition.fargate_task.arn
    task_count          = 1
    launch_type         = "FARGATE"
    network_configuration {
      subnets         = ["subnet-08cf0225585ba0ca5"]
      security_groups = ["sg-010b7b0b62f7b3b2c"]
    }
  }
}
