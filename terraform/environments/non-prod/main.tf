# Provider configuration
provider "aws" {
  region = "ap-south-2"
}

# Notifications module - SNS topic for patch alerts
module "notifications" {
  source             = "../../modules/notifications"
  environment        = "non-prod"
  project_name       = "cloud-governance-platform"
  notification_email = "praneeth.u.k@gmail.com"  # ← Replace with your actual email
}

# Call the VPC module
module "vpc" {
  source       = "../../modules/vpc"
  environment  = "non-prod"
  vpc_cidr     = "10.0.0.0/16"
  project_name = "cloud-governance-platform"
}

# Call the EC2 module
module "ec2" {
  source         = "../../modules/ec2"
  environment    = "non-prod"
  project_name   = "cloud-governance-platform"
  instance_count = 2
  instance_type  = "t3.micro"
  subnet_id      = module.vpc.private_subnet_id
  vpc_id         = module.vpc.vpc_id
}

# Call the Patch Management module
module "patch_management" {
  source                      = "../../modules/patch-management"
  environment                 = "non-prod"
  project_name                = "cloud-governance-platform"
  patch_approval_days         = 3
  maintenance_window_schedule = "cron(0 2 ? * SUN#1 *)"
  sns_topic_arn               = module.notifications.sns_topic_arn
}

# Call the Lambda module
module "lambda" {
  source             = "../../modules/lambda"
  environment        = "non-prod"
  project_name       = "cloud-governance-platform"
  sns_topic_arn      = module.notifications.sns_topic_arn
  lambda_source_path = "../../../lambda/patch-compliance-reporter"
}

# Outputs
output "non_prod_vpc_id" {
  value = module.vpc.vpc_id
}

output "non_prod_instance_ids" {
  value = module.ec2.instance_ids
}

output "non_prod_patch_baseline" {
  value = module.patch_management.patch_baseline_name
}

output "non_prod_maintenance_window" {
  value = module.patch_management.maintenance_window_name
}

output "non_prod_sns_topic" {
  value = module.notifications.sns_topic_name
}
output "non_prod_lambda_function" {
  value = module.lambda.lambda_function_name
}

output "non_prod_compliance_bucket" {
  value = module.lambda.compliance_bucket_name
}