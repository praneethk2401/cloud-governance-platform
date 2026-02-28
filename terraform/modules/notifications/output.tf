output "sns_topic_arn" {
  description = "ARN of the SNS topic for patch notifications"
  value       = aws_sns_topic.patch_notifications.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic"
  value       = aws_sns_topic.patch_notifications.name
}