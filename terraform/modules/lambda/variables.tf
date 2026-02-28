variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "cloud-governance-platform"
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for compliance notifications"
  type        = string
}

variable "lambda_source_path" {
  description = "Path to the Lambda function source code"
  type        = string
}