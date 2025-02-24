provider "aws" {
  region = var.aws_region  # Required for Cost Explorer
}

resource "aws_security_group" "trading_sg" {
  name_prefix = "trading-sg-"  # Unique name generation
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
  retention_in_days = 7  # Keep logs for 1 week
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
        "logs:DescribeLogGroups"
      ],
      Resource = "*"
    }]
  })
}

# 3. Update EC2 instance configuration
resource "aws_instance" "trading_bot" {
  ami           = "ami-0d3c032f5934e1b41"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name  # Add this
  
  user_data = <<-EOF
              #!/bin/bash
              # Install Docker and CloudWatch agent
              sudo apt-get update
              sudo apt-get install -y docker.io awscli
              
              # Run container with CloudWatch logging
              docker run -d \
                --log-driver=awslogs \
                --log-opt awslogs-region=us-east-1 \
                --log-opt awslogs-group=/ec2/trading-bot \
                --log-opt awslogs-stream=my-trading-strategy \
                your-docker-image
              EOF

  tags = {
    Name = "TradingBot"
  }
}

# 4. Add IAM role/profile
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




resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "strategy_data" {
  bucket = "cxmko-trading-bot-paris-${formatdate("YYYY-MM", timestamp())}-${random_id.bucket_suffix.hex}"
}

# Modern security controls (replaces ACLs)
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