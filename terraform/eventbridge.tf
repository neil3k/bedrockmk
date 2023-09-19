resource "aws_cloudwatch_event_rule" "stop_instances" {
  name                = "StopInstance"
  description         = "Stop instances nightly"
  schedule_expression = "cron(22 0 * * ? *)"
}

resource "aws_cloudwatch_event_target" "stop_lambda" {
  arn  = aws_lambda_function.stop_minecraft.arn
  rule = aws_cloudwatch_event_rule.stop_instances.id
}

resource "aws_cloudwatch_event_target" "stop_notification" {
  arn  = aws_sns_topic.user_updates.id
  rule = aws_cloudwatch_event_rule.stop_instances.name
}

resource "aws_cloudwatch_event_rule" "start_instances" {
  name                = "StartInstance"
  description         = "Start instances nightly"
  schedule_expression = "cron(15 0 * * ? *)"
}

resource "aws_cloudwatch_event_target" "start_lambda" {
  arn  = aws_lambda_function.start_minecraft.arn
  rule = aws_cloudwatch_event_rule.start_instances.id
}

resource "aws_cloudwatch_event_target" "start_notification" {
  arn  = aws_sns_topic.user_updates.id
  rule = aws_cloudwatch_event_rule.start_instances.name
}