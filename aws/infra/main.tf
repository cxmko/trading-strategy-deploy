provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "trading_sg" {
  name_prefix = "trading-sg-"
  description = "Allow SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "trading_bot" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = "trading-bot-key"  # Must match AWS Console key name
  vpc_security_group_ids = [aws_security_group.trading_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo usermod -aG docker ubuntu
              git clone https://github.com/cxmko/trading-strategy-deploy.git
              cd trading-strategy-deploy/aws
              sudo docker build -t trading-bot .
              sudo docker run -d \
                --log-driver=json-file \
                --log-opt max-size=10m \
              trading-bot
              EOF
}

output "instance_public_ip" {
  value = aws_instance.trading_bot.public_ip
}

