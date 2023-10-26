resource "aws_lambda_function" "start_minecraft" {
  function_name = "start_minecraft"
  role          = aws_iam_role.lambda_minecraft_role.arn
  runtime       = "python3.9"
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
  runtime       = "python3.9"
  filename      = "lambda.zip"
  handler       = "lambda_stop.lambda_handler"

  environment {
    variables = {
      instances = aws_instance.Minecraft.id
    }
  }
}