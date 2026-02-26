# Provider configuration
provider "aws" {
  region = "ap-south-2"
}

# Call the VPC module
module "vpc" {
  source       = "../../modules/vpc"
  environment  = "dr"
  vpc_cidr     = "10.2.0.0/16"
  project_name = "cloud-governance-platform"
}

# Call the EC2 module
module "ec2" {
  source         = "../../modules/ec2"
  environment    = "dr"
  project_name   = "cloud-governance-platform"
  instance_count = 2
  instance_type  = "t3.micro"
  subnet_id      = module.vpc.private_subnet_id
  vpc_id         = module.vpc.vpc_id
}

# Outputs
output "dr_vpc_id" {
  description = "DR VPC ID"
  value       = module.vpc.vpc_id
}

output "dr_instance_ids" {
  description = "DR EC2 Instance IDs"
  value       = module.ec2.instance_ids
}

output "dr_private_ips" {
  description = "DR EC2 Private IPs"
  value       = module.ec2.instance_private_ips
}