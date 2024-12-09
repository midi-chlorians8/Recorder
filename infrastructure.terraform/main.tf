terraform {
  required_version = "~> 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "eu-north-1" # Стокгольм
  # Доступ к AWS (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY) предполагается в окружении или в файле профиля.
}

# Поиск AMI для Ubuntu 24.04 (предполагается, что к моменту использования AMI доступна)
data "aws_ami" "ubuntu" {
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Скрипт для установки Docker и Docker Compose
locals {
  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg lsb-release

    # Установка Docker из официального репо
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Для удобства создать ссылку docker-compose
    ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose

    systemctl enable docker
    systemctl start docker
  EOF
}

resource "aws_instance" "recorder_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = "recorder_key"

  # 30GB диск
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }
  
  vpc_security_group_ids = [aws_security_group.allow_all_inbound.id]

  # Используем дефолтную VPC, не задавая subnet_id 
  associate_public_ip_address = true

  user_data = local.user_data

  tags = {
    Name    = "recorder-instance"
    Project = "recorder"
  }
}
