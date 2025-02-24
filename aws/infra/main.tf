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





resource "aws_instance" "trading_bot" {
  ami                  = "ami-0d3c032f5934e1b41"  # Ubuntu 22.04 LTS
  instance_type        = "t2.micro"


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
              docker run -d \
                --log-driver=awslogs \
                --log-opt awslogs-region=eu-west-3 \
                --log-opt awslogs-group=/trading/bot \
                trading-bot
              EOF

  tags = {
    Name = "TradingBot"
  }


}

resource "aws_s3_bucket" "strategy_data" {
  bucket = "cxmko-trading-bot-paris-${formatdate("YYYY-MM", timestamp())}"
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