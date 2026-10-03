
# FIAP MBA - Exercicio de infraestrutura com Terraform
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0
# Fiap MBA SCJ

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.52.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }

  required_version = ">= 1.1.0"

  cloud {
    organization = "DevopsFiapErica"

    workspaces {
      name = "gh-actions"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "random_pet" "sg" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web-sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y apache2
              sed -i -e 's/80/8080/' /etc/apache2/ports.conf
              echo "<style> body {background-color: blue;}</style><img src="https://postech.fiap.com.br/imgs/fiap-plus-alura/fiap_alura.png">" > /var/www/html/index.html
              systemctl restart apache2
              EOF
}

resource "aws_security_group" "web-sg" {
  name = "${random_pet.sg.id}-sg"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permite acesso aos repositorios Ubuntu para instalar o Apache
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/*
resource "aws_iam_user" "new_user" {
  name = "User_Fiap"

  tags = {
    Name = "Example User"
  }
}

resource "aws_iam_access_key" "new_user_access_key" {
  user = aws_iam_user.new_user.name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_user_policy_attachment" "new_user_policy_attachment" {
  user       = aws_iam_user.new_user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
*/

output "web-address" {
  value = "${aws_instance.web.public_dns}:8080"
}
