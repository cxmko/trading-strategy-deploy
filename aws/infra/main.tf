provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "trading_sg" {
  name_prefix = "trading-sg-"
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

# 1. Create CloudWatch Log Group
resource "aws_cloudwatch_log_group" "trading_logs" {
  name              = "/ec2/trading-bot"
  retention_in_days = 7
}

# 2. Add IAM permissions for CloudWatch
resource "aws_iam_role_policy" "ec2_cloudwatch" {
  name = "EC2-CloudWatch-Logs"
  role = aws_iam_role.ec2_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      Resource = "*"
    }]
  })
}

# 3. Update EC2 instance configuration with direct Docker build
resource "aws_instance" "trading_bot" {
  ami                  = "ami-0d3c032f5934e1b41"
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.trading_sg.id]
  
  user_data = <<-EOF
              #!/bin/bash
              set -e

              # Install Docker and AWS CLI
              apt-get update
              apt-get install -y docker.io awscli git

              # Clone your repository
              git clone https://github.com/cxmko/trading-strategy-deploy.git /app
              cd /app

              # Build Docker image locally
              docker build -t trading-bot .

              # Run container with CloudWatch logging
              docker run \
                --log-driver=awslogs \
                --log-opt awslogs-region=${var.aws_region} \
                --log-opt awslogs-group=/ec2/trading-bot \
                --log-opt awslogs-stream=strategy-output \
                --log-opt awslogs-create-group=true \
                trading-bot
              EOF

  tags = {
    Name = "TradingBot"
  }
}

# 4. IAM role/profile
resource "aws_iam_role" "ec2_role" {
  name = "EC2-CloudWatch-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2-CloudWatch-Profile"
  role = aws_iam_role.ec2_role.name
}

