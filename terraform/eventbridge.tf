resource "aws_scheduler_schedule" "stop_minecraft" {
  name       = "stop_minecraft"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 20 * * ? *)"

  target {
    arn      = aws_lambda_function.stop_minecraft.arn
    role_arn = aws_iam_role.scheduler_minecraft_role.arn
  }
}

resource "aws_scheduler_schedule" "start_minecraft" {
  name       = "start_minecraft"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 15 * * ? *)"

  target {
    arn      = aws_lambda_function.start_minecraft.arn
    role_arn = aws_iam_role.scheduler_minecraft_role.arn
  }
}