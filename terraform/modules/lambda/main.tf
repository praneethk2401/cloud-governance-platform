# S3 Bucket for compliance reports
resource "aws_s3_bucket" "compliance_reports" {
  bucket = "${var.project_name}-${var.environment}-compliance-reports"

  tags = {
    Name        = "${var.project_name}-${var.environment}-compliance-reports"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Block all public access to the bucket
resource "aws_s3_bucket_public_access_block" "compliance_reports" {
  bucket = aws_s3_bucket.compliance_reports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-lambda-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-${var.environment}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:DescribeInstancePatchStatesForPatchGroup",
          "ssm:DescribeInstancePatchStates",
          "ssm:DescribePatchGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.compliance_reports.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = var.sns_topic_arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Zip the Lambda source code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.lambda_source_path
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda Function
resource "aws_lambda_function" "patch_compliance_reporter" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-${var.environment}-patch-compliance-reporter"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 60

  environment {
    variables = {
      COMPLIANCE_BUCKET = aws_s3_bucket.compliance_reports.bucket
      SNS_TOPIC_ARN     = var.sns_topic_arn
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-patch-compliance-reporter"
    Environment = var.environment
    Project     = var.project_name
  }
}

# EventBridge rule to trigger Lambda monthly
resource "aws_cloudwatch_event_rule" "monthly_compliance_check" {
  name                = "${var.project_name}-${var.environment}-monthly-compliance"
  description         = "Trigger patch compliance report monthly"
  schedule_expression = "cron(0 6 ? * SUN#1 *)"

  tags = {
    Name        = "${var.project_name}-${var.environment}-monthly-compliance"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Allow EventBridge to invoke Lambda
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.monthly_compliance_check.name
  target_id = "PatchComplianceLambda"
  arn       = aws_lambda_function.patch_compliance_reporter.arn
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.patch_compliance_reporter.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.monthly_compliance_check.arn
}