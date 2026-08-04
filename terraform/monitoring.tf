# CloudWatch alarm for EC2 instance status check failures
resource "aws_cloudwatch_metric_alarm" "minecraft_health" {
  alarm_name          = "minecraft-instance-health"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Minecraft server instance has failed status checks"
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  ok_actions          = [aws_sns_topic.user_updates.arn]

  dimensions = {
    InstanceId = aws_instance.Minecraft.id
  }
}

# Auto-recover the instance if the underlying hardware fails
resource "aws_cloudwatch_metric_alarm" "minecraft_auto_recover" {
  alarm_name          = "minecraft-auto-recover"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Auto-recover Minecraft instance on system failure"
  alarm_actions       = ["arn:aws:automate:${var.aws_region}:ec2:recover"]

  dimensions = {
    InstanceId = aws_instance.Minecraft.id
  }
}
