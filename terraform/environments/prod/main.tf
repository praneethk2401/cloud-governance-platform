# Provider configuration
provider "aws" {
  region = "ap-south-2"
}

# Call the VPC module
module "vpc" {
  source       = "../../modules/vpc"
  environment  = "prod"
  vpc_cidr     = "10.1.0.0/16"
  project_name = "cloud-governance-platform"
}

# Call the EC2 module
module "ec2" {
  source         = "../../modules/ec2"
  environment    = "prod"
  project_name   = "cloud-governance-platform"
  instance_count = 2
  instance_type  = "t3.micro"
  subnet_id      = module.vpc.private_subnet_id
  vpc_id         = module.vpc.vpc_id
}

# Outputs
output "prod_vpc_id" {
  description = "Prod VPC ID"
  value       = module.vpc.vpc_id
}

output "prod_instance_ids" {
  description = "Prod EC2 Instance IDs"
  value       = module.ec2.instance_ids
}

output "prod_private_ips" {
  description = "Prod EC2 Private IPs"
  value       = module.ec2.instance_private_ips
}