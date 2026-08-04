variable "vpc_id" {
  type    = string
  default = "vpc-0e1e9504d0bd089a6"
}

variable "subnet_id" {
  type    = string
  default = "subnet-0def9a532dead7400"
}

variable "instance_size" {
  type    = string
  default = "t3.small"
}

variable "domain" {
  type    = string
  default = "pattersonminecraft.com"
}

variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "notification_numbers" {
  type        = list(string)
  description = "Phone numbers for SNS notifications"
  sensitive   = true
}
