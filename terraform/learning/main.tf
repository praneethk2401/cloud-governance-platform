# This tells Terraform we are using AWS and which region
provider "aws" {
  region = "ap-south-2"
}

variable "environment" {
  description = "Environemnt name"
  type = string
  default = "learning"
}

variable "project_name" {
  description = "Project name"
  type = string
  default = "cloud-governance-platform"
}

# This creates one S3 bucket in your AWS account
resource "aws_s3_bucket" "my_first_bucket" {
  bucket = "${var.project_name}-${var.environment}-praneeth-2026"

  tags = {
    Name        = "Governance Platform S3 Bucket"
    Environment = var.environment
    Project     = var.project_name
  }
}

output "bucket_name" {
  description = "The name of the S3 bucket created"
  value       = aws_s3_bucket.my_first_bucket.bucket
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.my_first_bucket.arn
}

output "environment" {
  description = "The environment this bucket belongs to"
  value       = var.environment
}