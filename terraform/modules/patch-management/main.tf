# Patch Baseline
resource "aws_ssm_patch_baseline" "main" {
  name             = "${var.project_name}-${var.environment}-patch-baseline"
  description      = "Patch baseline for ${var.environment} environment"
  operating_system = "AMAZON_LINUX_2"

  approval_rule {
    approve_after_days  = var.patch_approval_days
    enable_non_security = false

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Security", "Bugfix"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Critical", "Important"]
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-patch-baseline"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Register Patch Baseline as default for this Patch Group
resource "aws_ssm_patch_group" "main" {
  baseline_id = aws_ssm_patch_baseline.main.id
  patch_group = var.environment
}

# Maintenance Window
resource "aws_ssm_maintenance_window" "main" {
  name                       = "${var.project_name}-${var.environment}-maintenance-window"
  schedule                   = var.maintenance_window_schedule
  duration                   = var.maintenance_window_duration
  cutoff                     = var.maintenance_window_cutoff
  allow_unassociated_targets = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-maintenance-window"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Maintenance Window Target
resource "aws_ssm_maintenance_window_target" "main" {
  window_id     = aws_ssm_maintenance_window.main.id
  name          = "${var.project_name}-${var.environment}-patch-target"
  description   = "EC2 instances for ${var.environment} patching"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:Patch_Group"
    values = [var.environment]
  }
}

# Maintenance Window Task
resource "aws_ssm_maintenance_window_task" "patch_task" {
  window_id        = aws_ssm_maintenance_window.main.id
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline"
  priority         = 1
  max_concurrency = "50%"
  max_errors = "20%"
  service_role_arn = aws_iam_role.maintenance_window_role.arn

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.main.id]
  }

  task_invocation_parameters {
  run_command_parameters {
    service_role_arn = aws_iam_role.maintenance_window_role.arn
    parameter {
      name   = "Operation"
      values = ["Install"]
    }
    parameter {
      name   = "RebootOption"
      values = ["RebootIfNeeded"]
    }
    notification_config {
      notification_arn    = var.sns_topic_arn
      notification_events = ["Success", "Failed"]
      notification_type   = "Command"
    }
  }
}
}

# IAM Role for Maintenance Window
resource "aws_iam_role" "maintenance_window_role" {
  name = "${var.project_name}-${var.environment}-maintenance-window-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ssm.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-maintenance-window-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach policy to IAM Role
resource "aws_iam_role_policy_attachment" "maintenance_window_policy" {
  role       = aws_iam_role.maintenance_window_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMMaintenanceWindowRole"
}