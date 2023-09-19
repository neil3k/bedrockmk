variable "vpc_id" {
  type    = string
  default = "vpc-0e1e9504d0bd089a6"
}

variable "subnet_id" {
  type    = string
  default = "subnet-0def9a532dead7400"
}

variable "mojang_server_url" {
  type    = string
  default = "https://piston-data.mojang.com/v1/objects/84194a2f286ef7c14ed7ce0090dba59902951553/server.jar"
}

variable "instance_size" {
  type    = string
  default = "t2.small"
}

variable "domain" {
  type    = string
  default = "pattersonminecraft.com"
}