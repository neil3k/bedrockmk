# SSM Patch Management for Ubuntu OS patching

resource "aws_ssm_patch_baseline" "minecraft_baseline" {
  name             = "minecraft-ubuntu-baseline"
  description      = "Patch baseline for Minecraft Ubuntu servers"
  operating_system = "UBUNTU"

  approval_rule {
    approve_after_days  = 0
    compliance_level    = "CRITICAL"
    enable_non_security = false

    patch_filter {
      key    = "PRIORITY"
      values = ["Required", "Important", "Standard", "Optional", "Extra"]
    }
    patch_filter {
      key    = "SECTION"
      values = ["*"]
    }
  }

  approval_rule {
    approve_after_days  = 7
    compliance_level    = "HIGH"
    enable_non_security = true

    patch_filter {
      key    = "PRIORITY"
      values = ["Required", "Important", "Standard"]
    }
  }

  tags = {
    Name = "minecraft-patch-baseline"
  }
}

resource "aws_ssm_patch_group" "minecraft_patch_group" {
  baseline_id = aws_ssm_patch_baseline.minecraft_baseline.id
  patch_group = "minecraft-servers"
}

resource "aws_ssm_association" "minecraft_patch_association" {
  name                = "AWS-RunPatchBaseline"
  schedule_expression = "rate(1 day)"

  parameters = {
    Operation = "Scan"
  }

  targets {
    key    = "tag:Name"
    values = ["Bedrock Minecraft Server"]
  }
}

# Maintenance window for patching (Sundays at 2am)
resource "aws_ssm_maintenance_window" "minecraft_maintenance" {
  name        = "minecraft-patch-maintenance"
  description = "Maintenance window for Minecraft server patching"
  schedule    = "cron(0 2 ? * SUN *)"
  duration    = 4
  cutoff      = 1

  tags = {
    Name = "minecraft-maintenance-window"
  }
}

resource "aws_ssm_maintenance_window_target" "minecraft_target" {
  window_id     = aws_ssm_maintenance_window.minecraft_maintenance.id
  name          = "minecraft-instance-target"
  description   = "Minecraft EC2 instance for patching"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:Name"
    values = ["Bedrock Minecraft Server"]
  }
}

resource "aws_ssm_maintenance_window_task" "minecraft_patch_task" {
  window_id        = aws_ssm_maintenance_window.minecraft_maintenance.id
  name             = "minecraft-patch-install"
  description      = "Install patches on Minecraft server"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline"
  priority         = 1
  service_role_arn = aws_iam_role.patch_maintenance_role.arn
  max_concurrency  = "1"
  max_errors       = "0"

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.minecraft_target.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "Operation"
        values = ["Install"]
      }
      parameter {
        name   = "RebootOption"
        values = ["RebootIfNeeded"]
      }
    }
  }
}

resource "aws_ssm_maintenance_window_task" "minecraft_patch_scan" {
  window_id        = aws_ssm_maintenance_window.minecraft_maintenance.id
  name             = "minecraft-patch-scan"
  description      = "Scan for available patches on Minecraft server"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline"
  priority         = 2
  service_role_arn = aws_iam_role.patch_maintenance_role.arn
  max_concurrency  = "1"
  max_errors       = "0"

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.minecraft_target.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "Operation"
        values = ["Scan"]
      }
    }
  }
}

# IAM role for patch maintenance
resource "aws_iam_role" "patch_maintenance_role" {
  name = "minecraft-patch-maintenance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "minecraft-patch-maintenance-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ssm:SendCommand",
            "ssm:ListCommands",
            "ssm:ListCommandInvocations",
            "ssm:DescribeInstanceInformation",
            "ssm:GetCommandInvocation",
            "ssm:GetDocument",
            "ssm:ListDocuments",
          ]
          Resource = "*"
        },
        {
          Effect   = "Allow"
          Action   = ["ec2:DescribeInstances"]
          Resource = "*"
        }
      ]
    })
  }

  tags = {
    Name = "minecraft-patch-maintenance-role"
  }
}

# SNS topic for patch notifications
resource "aws_sns_topic" "patch_notifications" {
  name = "minecraft-patch-notifications"

  tags = {
    Name = "minecraft-patch-notifications"
  }
}

resource "aws_sns_topic_policy" "patch_notifications_policy" {
  arn = aws_sns_topic.patch_notifications.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "patch-notifications-policy"
    Statement = [
      {
        Sid       = "AllowCloudWatchEvents"
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.patch_notifications.arn
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "patch_email_notification" {
  topic_arn = aws_sns_topic.patch_notifications.arn
  protocol  = "email"
  endpoint  = "neil3k@gmail.com"
}

# CloudWatch event rule for patch compliance notifications
resource "aws_cloudwatch_event_rule" "patch_compliance" {
  name        = "minecraft-patch-compliance"
  description = "Monitor patch compliance for Minecraft server"

  event_pattern = jsonencode({
    source      = ["aws.ssm"]
    detail-type = ["EC2 Command Status-change Notification", "EC2 Command Invocation Status-change Notification"]
    detail = {
      document-name = ["AWS-RunPatchBaseline"]
      status        = ["Success", "Failed", "InProgress", "Cancelled", "TimedOut"]
    }
  })

  tags = {
    Name = "minecraft-patch-compliance-rule"
  }
}

resource "aws_cloudwatch_event_target" "patch_notification_target" {
  rule      = aws_cloudwatch_event_rule.patch_compliance.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.patch_notifications.arn

  input_transformer {
    input_paths = {
      instance = "$.detail.instance-id"
      status   = "$.detail.status"
      command  = "$.detail.command-id"
      time     = "$.time"
    }
    input_template = jsonencode({
      notification = "Minecraft Server Patch Update"
      instance_id  = "<instance>"
      status       = "<status>"
      command_id   = "<command>"
      timestamp    = "<time>"
      message      = "Patch operation <status> on Minecraft server instance <instance> at <time>"
    })
  }
}

# CloudWatch event rule for maintenance window execution
resource "aws_cloudwatch_event_rule" "maintenance_window_execution" {
  name        = "minecraft-maintenance-window-execution"
  description = "Monitor maintenance window execution for Minecraft server"

  event_pattern = jsonencode({
    source      = ["aws.ssm"]
    detail-type = ["Maintenance Window State Change", "Maintenance Window Target Registration Change", "Maintenance Window Execution State Change"]
    detail = {
      window-id = [aws_ssm_maintenance_window.minecraft_maintenance.id]
    }
  })

  tags = {
    Name = "minecraft-maintenance-window-rule"
  }
}

resource "aws_cloudwatch_event_target" "maintenance_notification_target" {
  rule      = aws_cloudwatch_event_rule.maintenance_window_execution.name
  target_id = "SendMaintenanceToSNS"
  arn       = aws_sns_topic.patch_notifications.arn

  input_transformer {
    input_paths = {
      window_id = "$.detail.window-id"
      status    = "$.detail.status"
      time      = "$.time"
    }
    input_template = jsonencode({
      notification = "Minecraft Server Maintenance Window Update"
      window_id    = "<window_id>"
      status       = "<status>"
      timestamp    = "<time>"
      message      = "Maintenance window execution <status> for Minecraft server at <time>"
    })
  }
}
