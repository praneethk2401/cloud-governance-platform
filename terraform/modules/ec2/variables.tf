variable "environment" {
  description = "Environment name (non-prod, prod, dr)"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "cloud-governance-platform"
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID where EC2 instances will be launched"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EC2 instances will be launched"
  type        = string
}