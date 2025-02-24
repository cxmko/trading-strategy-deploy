provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "trading_bot" {
  ami           = "ami-0d3c032f5934e1b41"
  instance_type = "t2.micro"
  tags = {
    Name = "TradingBot"
  }
}

resource "aws_s3_bucket" "strategy_data" {
  bucket = "cxmko-trading-bot-paris-2024"
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

