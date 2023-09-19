
resource "aws_security_group" "minecraft_bedrock" {
  name   = "Bedrock Minecraft Server"
  vpc_id = data.aws_vpc.selected.id

  ingress {
    description = "Receive Minecraft from everywhere."
    from_port   = 19133
    to_port     = 19133
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Receive Minecraft from everywhere."
    from_port   = 19132
    to_port     = 19132
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Receive http from everywhere."
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Receive https from everywhere."
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Send everywhere."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Minecraft"
  }
}

data "aws_key_pair" "minecraft" {
  key_name = "minecraft"
}

resource "aws_instance" "Minecraft" {
  ami                         = "ami-007ec828a062d87a5"
  instance_type               = var.instance_size
  subnet_id                   = data.aws_subnet.this.id
  associate_public_ip_address = false
  iam_instance_profile        = "neilsec2ssm"
  key_name                    = data.aws_key_pair.minecraft.key_name
  vpc_security_group_ids      = [aws_security_group.minecraft_bedrock.id]
  user_data                   = file("minecraft.sh")

  tags = {
    Name = "Bedrock Minecraft Server"
  }

  depends_on = [aws_security_group.minecraft_bedrock]
}

resource "aws_eip" "Minecraft_bedrock" {
  instance = aws_instance.Minecraft.id

  tags = {
    Name = "MineCraft IP"
  }
  depends_on = [aws_instance.Minecraft]
}