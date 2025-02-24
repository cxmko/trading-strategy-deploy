provider "aws" {
  region = var.aws_region  # Required for Cost Explorer
}

resource "aws_security_group" "trading_sg" {
  name        = "trading-sg"
  description = "Allow SSH and trading traffic"

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

resource "aws_iam_role_policy_attachment" "cost_explorer" {
  role       = aws_iam_role.trading_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCostExplorerReadOnlyAccess"
}

resource "aws_iam_instance_profile" "trading_profile" {
  name = "trading-instance-profile"
  role = aws_iam_role.trading_role.name
}

resource "aws_instance" "trading_bot" {
  ami                  = "ami-0c55b159cbfafe1f0"  # Ubuntu 22.04 LTS
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.trading_profile.name
  security_groups      = [aws_security_group.trading_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              # Install Docker
              sudo apt-get update
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              
              # Clone repository
              git clone https://github.com/cxmko/trading-strategy-deploy.git
              cd trading-strategy-deploy/aws
              
              # Build and run Docker
              docker build -t trading-bot .
              docker run -d trading-bot
              EOF

  tags = {
    Name = "TradingBot"
  }
}