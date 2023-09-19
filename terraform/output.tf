output "public_ip" {
  value = aws_eip.Minecraft_bedrock.public_ip
}

output "instance_id" {
  value = aws_instance.Minecraft.id
}

output "instance_arn" {
  value = aws_instance.Minecraft.arn
}