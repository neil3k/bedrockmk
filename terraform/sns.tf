resource "aws_sns_topic" "user_updates" {
  name = "minecraft_notifications"
}

resource "aws_sns_topic_subscription" "minecraft_sub" {
  endpoint  = "+447867787231"
  protocol  = "sms"
  topic_arn = aws_sns_topic.user_updates.id
}

resource "aws_sns_topic_subscription" "minecraft_jodie" {
  endpoint  = "+447598467213"
  protocol  = "sms"
  topic_arn = aws_sns_topic.user_updates.id
}