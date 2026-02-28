output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.patch_compliance_reporter.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.patch_compliance_reporter.arn
}

output "compliance_bucket_name" {
  description = "Name of the S3 compliance reports bucket"
  value       = aws_s3_bucket.compliance_reports.bucket
}

output "compliance_bucket_arn" {
  description = "ARN of the S3 compliance reports bucket"
  value       = aws_s3_bucket.compliance_reports.arn
}