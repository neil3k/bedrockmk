data "aws_canonical_user_id" "current" {}
data "aws_caller_identity" "current" {}

#We have a pre-existing VPC
data "aws_vpc" "selected" {
  id = var.vpc_id
}

#Gather Subnet information
data "aws_subnet" "this" {
  id = var.subnet_id
}