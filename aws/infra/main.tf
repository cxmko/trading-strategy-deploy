provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "trading_bot" {
  ami           = "ami-0d3c032f5934e1b41" # Ubuntu 22.04
  instance_type = "t2.micro"
  
  # Allow SSH access
  vpc_security_group_ids = [aws_security_group.trading_sg.id]
  
  # Build and run Docker directly
  user_data = <<-EOF
              #!/bin/bash
              # Install Docker
              sudo apt-get update
              sudo apt-get install -y docker.io
              
              # Clone repo
              git clone https://github.com/cxmko/trading-strategy-deploy.git
              cd trading-strategy-deploy/aws
              
              # Build and run container
              docker build -t trading-bot .
              docker run -d trading-bot
              EOF

  tags = {
    Name = "TradingBot"
  }
}

resource "aws_security_group" "trading_sg" {
  name_prefix = "trading-sg-"
  description = "Allow SSH and outbound traffic"

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