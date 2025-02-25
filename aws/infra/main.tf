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

# Use data source to reference existing IAM role
data "aws_iam_role" "ec2_role" {
  name = "EC2-CloudWatch-Role"
}

data "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2-CloudWatch-Profile"
}

# Create S3 bucket for logs
resource "aws_s3_bucket" "trading_logs_bucket" {
  bucket = "trading-logs-${formatdate("YYMMDDhhmmss", timestamp())}"

  tags = {
    Name = "Trading Bot Logs"
  }
}

# Update IAM policy to allow S3 access
resource "aws_iam_role_policy" "ec2_s3_access" {
  name = "EC2-S3-Access-${formatdate("YYMMDDhhmmss", timestamp())}"
  role = data.aws_iam_role.ec2_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      Resource = [
        aws_s3_bucket.trading_logs_bucket.arn,
        "${aws_s3_bucket.trading_logs_bucket.arn}/*"
      ]
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

              # Create logs directory
              mkdir -p /app/logs

              # Build Docker image locally
              docker build -t trading-bot .

              # Create unique log filename with timestamp
              TIMESTAMP=$(date +%Y%m%d%H%M%S)
              LOG_FILE="trading-output-$TIMESTAMP.log"
              
              # Run container with output to file
              docker run --name trading-container -d trading-bot
              
              # Give the container some time to run and generate output
              sleep 60
              
              # Get logs from the container
              docker logs trading-container > /app/logs/$LOG_FILE 2>&1
              
              # Upload log file to S3
              aws s3 cp /app/logs/$LOG_FILE s3://${aws_s3_bucket.trading_logs_bucket.bucket}/$LOG_FILE
              
              # Create a metadata file with the log information
              echo "LOG_BUCKET=${aws_s3_bucket.trading_logs_bucket.bucket}" > /app/logs/log_info.txt
              echo "LOG_FILE=$LOG_FILE" >> /app/logs/log_info.txt
              
              # Upload metadata file to S3 as well
              aws s3 cp /app/logs/log_info.txt s3://${aws_s3_bucket.trading_logs_bucket.bucket}/log_info.txt
              EOF

  tags = {
    Name = "TradingBot-${formatdate("YYMMDDhhmmss", timestamp())}"
  }
}

# Output information to help retrieve logs
output "logs_bucket" {
  value = aws_s3_bucket.trading_logs_bucket.bucket
}

output "ec2_instance_id" {
  value = aws_instance.trading_bot.id
}