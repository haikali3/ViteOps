resource "aws_ecs_cluster" "fargate_cluster" {
  name = "fargate-cluster"
}

resource "aws_ecs_task_definition" "fargate_task" {
  family                   = "fargate-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.fargate_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "fargate-container",
      image     = data.aws_ecr_repository.repo.repository_url,
      essential = true,
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
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = "/ecs/fargate-task",
          "awslogs-region"        = "ap-southeast-1",
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

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
