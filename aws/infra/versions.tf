terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"  # Supports new S3 ACL syntax
    }
  }
}
