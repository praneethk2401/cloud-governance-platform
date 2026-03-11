output "remediation_lambda_name" {
  description = "Name of the remediation Lambda function"
  value       = aws_lambda_function.vulnerability_remediator.function_name
}

output "remediation_lambda_arn" {
  description = "ARN of the remediation Lambda function"
  value       = aws_lambda_function.vulnerability_remediator.arn
}

output "security_hub_rule_name" {
  description = "Name of the EventBridge rule for Security Hub findings"
  value       = aws_cloudwatch_event_rule.security_hub_findings.name
}