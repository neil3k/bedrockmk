
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
    description = "Receive ssh from everywhere."
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Receive Minecraft from everywhere."
    from_port   = 19132
    to_port     = 19132
    protocol    = "udp"
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
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ssm_ec2.id
  key_name                    = data.aws_key_pair.minecraft.key_name
  vpc_security_group_ids      = [aws_security_group.minecraft_bedrock.id]
  user_data                   = file("minecraft.sh")

  tags = {
    Name = "Bedrock Minecraft Server"
  }

  provisioner "file" {
    source      = file("upgrade.sh")
    destination = "/usr/games/"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_eip.Minecraft_bedrock.public_ip
      private_key = file("minecraft.ppk")
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /usr/games/upgrade.sh"
    ]
  }
}

resource "aws_eip" "Minecraft_bedrock" {
  tags = {
    Name = "MineCraft IP"
  }
}

resource "aws_eip_association" "eip_minecraft" {
  instance_id   = aws_instance.Minecraft.id
  allocation_id = aws_eip.Minecraft_bedrock.id
}