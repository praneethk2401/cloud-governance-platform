variable "environment" {
  description = "Environment name (non-prod, prod, dr)"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "cloud-governance-platform"
}

variable "notification_email" {
  description = "Email address to receive patch notifications"
  type        = string
}