resource "aws_sns_topic" "user_updates" {
  name = "minecraft_notifications"
}

resource "aws_sns_topic_subscription" "minecraft_sub" {
  endpoint  = var.notification_numbers[0]
  protocol  = "sms"
  topic_arn = aws_sns_topic.user_updates.id
}

resource "aws_sns_topic_subscription" "minecraft_jodie" {
  endpoint  = var.notification_numbers[1]
  protocol  = "sms"
  topic_arn = aws_sns_topic.user_updates.id
}