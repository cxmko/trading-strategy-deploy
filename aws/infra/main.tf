provider "aws" {
  region = var.aws_region
}

# Security group with name based on timestamp to avoid conflicts
resource "aws_security_group" "trading_sg" {
  name_prefix = "trading-sg-${formatdate("YYMMDDhhmmss", timestamp())}-"
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

  lifecycle {
    create_before_destroy = true
  }
}

# Use data source to reference existing log group
data "aws_cloudwatch_log_group" "trading_logs" {
  name = "/ec2/trading-bot"
}

# Use data source to reference existing IAM role and profile
data "aws_iam_role" "ec2_role" {
  name = "EC2-CloudWatch-Role"
}

data "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2-CloudWatch-Profile"
}

# Update IAM policy using the data source
resource "aws_iam_role_policy" "ec2_cloudwatch" {
  name = "EC2-CloudWatch-Logs-${formatdate("YYMMDDhhmmss", timestamp())}"
  role = data.aws_iam_role.ec2_role.name

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

# EC2 instance using existing profile
resource "aws_instance" "trading_bot" {
  ami                    = "ami-0d3c032f5934e1b41"
  instance_type          = "t2.micro"
  iam_instance_profile   = data.aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.trading_sg.id]
  
  user_data = <<-EOF
              #!/bin/bash
              set -e

              # Install Docker and AWS CLI
              apt-get update
              apt-get install -y docker.io awscli git

              # Clone your repository
              git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git /app
              cd /app

              # Build Docker image locally
              docker build -t trading-bot .

              # Create unique log stream name with timestamp
              TIMESTAMP=$(date +%Y%m%d%H%M%S)
              LOG_STREAM="trading-output-$TIMESTAMP"

              # Run container with CloudWatch logging
              docker run \
                --log-driver=awslogs \
                --log-opt awslogs-region=${var.aws_region} \
                --log-opt awslogs-group=/ec2/trading-bot \
                --log-opt awslogs-stream=$LOG_STREAM \
                trading-bot

              # Output the log stream name to a file for easy retrieval
              echo "LOG_STREAM=$LOG_STREAM" > /tmp/log_stream_info.txt
              EOF

  tags = {
    Name = "TradingBot-${formatdate("YYMMDDhhmmss", timestamp())}"
  }
}





# Output information to help retrieve logs
output "log_group_name" {
  value = data.aws_cloudwatch_log_group.trading_logs.name
}

output "ec2_instance_id" {
  value = aws_instance.trading_bot.id
}