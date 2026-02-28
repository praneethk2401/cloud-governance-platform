# SNS Topic for patch notifications
resource "aws_sns_topic" "patch_notifications" {
  name = "${var.project_name}-${var.environment}-patch-notifications"

  tags = {
    Name        = "${var.project_name}-${var.environment}-patch-notifications"
    Environment = var.environment
    Project     = var.project_name
  }
}

# SNS Topic Subscription - email endpoint
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.patch_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}