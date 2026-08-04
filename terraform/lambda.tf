resource "aws_lambda_function" "start_minecraft" {
  function_name = "start_minecraft"
  role          = aws_iam_role.lambda_minecraft_role.arn
  runtime       = "python3.12"
  filename      = "lambda.zip"
  handler       = "lambda_start.lambda_handler"

  environment {
    variables = {
      instances = aws_instance.Minecraft.id
    }
  }
}

resource "aws_lambda_function" "stop_minecraft" {
  function_name = "stop_minecraft"
  role          = aws_iam_role.lambda_minecraft_role.arn
  runtime       = "python3.12"
  filename      = "lambda.zip"
  handler       = "lambda_stop.lambda_handler"

  environment {
    variables = {
      instances = aws_instance.Minecraft.id
    }
  }
}

resource "aws_lambda_function" "backup_minecraft" {
  function_name = "backup_minecraft"
  role          = aws_iam_role.lambda_minecraft_role.arn
  runtime       = "python3.12"
  filename      = "lambda.zip"
  handler       = "lambda_backup.lambda_handler"
  timeout       = 120

  environment {
    variables = {
      instance_id   = aws_instance.Minecraft.id
      backup_bucket = aws_s3_bucket.minecraft_backups.id
    }
  }
}

resource "aws_lambda_function" "upgrade_minecraft" {
  function_name = "upgrade_minecraft"
  role          = aws_iam_role.lambda_minecraft_role.arn
  runtime       = "python3.12"
  filename      = "lambda.zip"
  handler       = "lambda_upgrade.lambda_handler"
  timeout       = 300

  environment {
    variables = {
      instance_id   = aws_instance.Minecraft.id
      backup_bucket = aws_s3_bucket.minecraft_backups.id
    }
  }
}

resource "aws_lambda_permission" "allow_scheduler_start" {
  statement_id  = "AllowExecutionFromScheduler"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_minecraft.function_name
  principal     = "scheduler.amazonaws.com"
  source_arn    = aws_scheduler_schedule.start_minecraft.arn
}

resource "aws_lambda_permission" "allow_scheduler_stop" {
  statement_id  = "AllowExecutionFromScheduler"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_minecraft.function_name
  principal     = "scheduler.amazonaws.com"
  source_arn    = aws_scheduler_schedule.stop_minecraft.arn
}
