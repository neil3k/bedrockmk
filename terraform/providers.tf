terraform {
  backend "s3" {
    bucket = "neilpatterson-terraform-state-backend"
    key    = "bedrock-minecraft/state/terraform.tfstate"
    region = "eu-west-2"
    # Replace this with your DynamoDB table name!
    dynamodb_table = "minecraft-terraform-state"
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-2"
}