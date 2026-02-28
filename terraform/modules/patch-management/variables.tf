variable "environment" {
    description = "Environment name (non-prod, prod, dr)"
    type = string
}

variable "project_name" {
    description = "Project name for tagging"
    type = string
    default = "cloud-governance-platform"
}

variable "patch_approval_days" {
    description = "Number of days before patches are automatically approved"
    type = number
}

variable "maintenance_window_schedule" {
    description = "Cron schedule for maintenance windows"
    type = string
}

variable "maintenance_window_duration" {
    description = "Duration of maintenance windows in hours"
    type = number
    default = 2
}

variable "maintenance_window_cutoff" {
    description = "Hours before end of windows to stop scheduling new tasks"
    type = number
    default = 1
}

variable "sns_topic_arn" {
    description = "SNS topic ARN for patch notifications"
    type = string
}

