output "patch_baseline_id" {
  description = "ID of the patch baseline"
  value       = aws_ssm_patch_baseline.main.id
}

output "patch_baseline_name" {
  description = "Name of the patch baseline"
  value       = aws_ssm_patch_baseline.main.name
}

output "maintenance_window_id" {
  description = "ID of the maintenance window"
  value       = aws_ssm_maintenance_window.main.id
}

output "maintenance_window_name" {
  description = "Name of the maintenance window"
  value       = aws_ssm_maintenance_window.main.name
}

output "maintenance_window_schedule" {
  description = "Schedule of the maintenance window"
  value       = aws_ssm_maintenance_window.main.schedule
}
