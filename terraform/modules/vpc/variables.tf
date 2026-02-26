variable "environment" {
  description = "Environment name (non-prod, prod, dr)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "cloud-governance-platform"
}

variable "enable_ssm_endpoints" {
  description = "Enable SSM VPC endpoints for private subnet access"
  type        = bool
  default     = true
}