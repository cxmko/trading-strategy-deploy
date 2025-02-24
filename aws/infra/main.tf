provider "aws" {
  region = var.aws_region  # Required for Cost Explorer
}


resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Security Group
resource "aws_security_group" "trading_sg" {
  name_prefix = "trading-sg-"
  description = "Allow SSH and trading traffic"
  vpc_id      = data.aws_vpc.default.id

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

data "aws_vpc" "default" {
  default = true
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "trading_logs" {
  name              = "/ec2/trading-bot"
  retention_in_days = 7
}

# IAM Role
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

resource "aws_iam_role_policy" "ec2_cloudwatch" {
  name = "EC2-CloudWatch-Logs"
  role = aws_iam_role.ec2_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:BatchGetImage"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2-CloudWatch-Profile"
  role = aws_iam_role.ec2_role.name
}

# ECR Repository
resource "aws_ecr_repository" "trading_repo" {
  name = "trading-bot"
}

# EC2 Instance
resource "aws_instance" "trading_bot" {
  ami                  = "ami-0d3c032f5934e1b41" # Ubuntu 22.04
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  security_groups      = [aws_security_group.trading_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y docker.io
              
              # Login to ECR
              aws ecr get-login-password --region us-east-1 | \
                docker login --username AWS --password-stdin ${aws_ecr_repository.trading_repo.repository_url}
              
              # Pull and run container
              docker pull ${aws_ecr_repository.trading_repo.repository_url}:latest
              docker run -d \
                --log-driver=awslogs \
                --log-opt awslogs-region=us-east-1 \
                --log-opt awslogs-group=/ec2/trading-bot \
                --log-opt awslogs-stream=instance-$(curl -s http://169.254.169.254/latest/meta-data/instance-id) \
                ${aws_ecr_repository.trading_repo.repository_url}:latest
              EOF

  tags = {
    Name = "TradingBot"
  }
}

# S3 Bucket
resource "aws_s3_bucket" "strategy_data" {
  bucket = "cxmko-trading-bot-paris-${formatdate("YYYY-MM", timestamp())}-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_ownership_controls" "strategy_data" {
  bucket = aws_s3_bucket.strategy_data.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "strategy_data" {
  bucket = aws_s3_bucket.strategy_data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}