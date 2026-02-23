# This tells Terraform we are using AWS and which region
provider "aws" {
  region = "ap-south-2"
}

# This creates one S3 bucket in your AWS account
resource "aws_s3_bucket" "my_first_bucket" {
  bucket = "praneeth-terraform-learning-2026"

  tags = {
    Name        = "My First Terraform Bucket"
    Environment = "learning"
    Project     = "cloud-governance-platform"
  }
}