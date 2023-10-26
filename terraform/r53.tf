data "aws_route53_zone" "minecraft" {
  name = var.domain
}

resource "aws_route53_record" "A" {
  zone_id = data.aws_route53_zone.minecraft.id
  name    = var.domain
  type    = "A"
  ttl     = 300
  records = [aws_eip.Minecraft_bedrock.public_ip]
}

resource "aws_route53_record" "Awww" {
  zone_id = data.aws_route53_zone.minecraft.id
  name    = "www.${var.domain}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.Minecraft_bedrock.public_ip]
}