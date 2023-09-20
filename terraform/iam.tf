resource "aws_iam_role" "lambda_minecraft_role" {
  name = "lambda_minecraft_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
  }
}

resource "aws_iam_role_policy" "lambda_minecraft_policy" {
  name = "lambda_minecraft_policy"
  role = aws_iam_role.lambda_minecraft_role.id

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : "arn:aws:logs:*:*:*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:Start*",
            "ec2:Stop*"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
}

resource "aws_iam_role" "scheduler_minecraft_role" {
  name = "scheduler_minecraft_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "scheduler.amazonaws.com"
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {
          "StringEquals" : {
            "aws:SourceAccount" : "320861227871"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "scheduler_role_policy" {
  role = aws_iam_role.scheduler_minecraft_role.id
  name = "scheduler_invoke_policy"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "lambda:InvokeFunction"
          ],
          "Resource" : [
            "arn:aws:lambda:eu-west-2:320861227871:function:start_minecraft:*",
            "arn:aws:lambda:eu-west-2:320861227871:function:start_minecraft"
          ]
        }
      ]
    }

  )
}