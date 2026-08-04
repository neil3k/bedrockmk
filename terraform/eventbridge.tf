resource "aws_scheduler_schedule" "stop_minecraft" {
  name       = "stop_minecraft"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(0 20 * * ? *)"
  schedule_expression_timezone = "Europe/London"

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

  schedule_expression          = "cron(0 15 * * ? *)"
  schedule_expression_timezone = "Europe/London"

  target {
    arn      = aws_lambda_function.start_minecraft.arn
    role_arn = aws_iam_role.scheduler_minecraft_role.arn
  }
}

# Daily world backup at 19:45 (just before server stops)
resource "aws_scheduler_schedule" "backup_minecraft" {
  name       = "backup_minecraft"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(45 19 * * ? *)"
  schedule_expression_timezone = "Europe/London"

  target {
    arn      = aws_lambda_function.backup_minecraft.arn
    role_arn = aws_iam_role.scheduler_minecraft_role.arn
  }
}

# Weekly auto-upgrade check (Wednesdays at 14:30, before server starts)
resource "aws_scheduler_schedule" "upgrade_minecraft" {
  name       = "upgrade_minecraft"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(30 14 ? * WED *)"
  schedule_expression_timezone = "Europe/London"

  target {
    arn      = aws_lambda_function.upgrade_minecraft.arn
    role_arn = aws_iam_role.scheduler_minecraft_role.arn
  }
}