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
