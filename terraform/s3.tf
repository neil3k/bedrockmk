resource "aws_s3_bucket" "minecraft_backups" {
  bucket = "bedrock-minecraft-backups"

  tags = {
    Name = "Minecraft_backups"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.minecraft_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}