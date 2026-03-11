# IAM Role for Remediation Lambda
resource "aws_iam_role" "remediation_lambda_role" {
  name = "${var.project_name}-${var.environment}-remediation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-remediation-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Policy for Remediation Lambda
resource "aws_iam_role_policy" "remediation_lambda_policy" {
  name = "${var.project_name}-${var.environment}-remediation-policy"
  role = aws_iam_role.remediation_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketVersioning",
          "s3:GetBucketPublicAccessBlock"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeSecurityGroups",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = var.sns_topic_arn
      },
      {
        Effect = "Allow"
        Action = [
          "securityhub:BatchUpdateFindings",
          "securityhub:GetFindings"
        ]
        Resource = "*"
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
data "archive_file" "remediation_zip" {
  type        = "zip"
  source_dir  = var.lambda_source_path
  output_path = "${path.module}/remediation_function.zip"
}

# Remediation Lambda Function
resource "aws_lambda_function" "vulnerability_remediator" {
  filename         = data.archive_file.remediation_zip.output_path
  function_name    = "${var.project_name}-${var.environment}-vulnerability-remediator"
  role             = aws_iam_role.remediation_lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.remediation_zip.output_base64sha256
  timeout          = 60

  environment {
    variables = {
      SNS_TOPIC_ARN = var.sns_topic_arn
      ENVIRONMENT   = var.environment
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-vulnerability-remediator"
    Environment = var.environment
    Project     = var.project_name
  }
}

# EventBridge Rule — triggers on HIGH/CRITICAL Security Hub findings
resource "aws_cloudwatch_event_rule" "security_hub_findings" {
  name        = "${var.project_name}-${var.environment}-security-findings"
  description = "Trigger remediation on HIGH or CRITICAL Security Hub findings"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity = {
          Label = ["HIGH", "CRITICAL"]
        }
        Workflow = {
          Status = ["NEW"]
        }
        RecordState = ["ACTIVE"]
      }
    }
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-security-findings"
    Environment = var.environment
    Project     = var.project_name
  }
}

# EventBridge Target — connects rule to Lambda
resource "aws_cloudwatch_event_target" "remediation_lambda" {
  rule      = aws_cloudwatch_event_rule.security_hub_findings.name
  target_id = "VulnerabilityRemediationLambda"
  arn       = aws_lambda_function.vulnerability_remediator.arn
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge_remediation" {
  statement_id  = "AllowEventBridgeInvokeRemediation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.vulnerability_remediator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.security_hub_findings.arn
}