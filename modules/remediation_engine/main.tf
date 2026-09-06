resource "aws_sns_topic" "security_alerts" {
  name = "${var.project_name}-security-alerts-${var.environment}"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.security_notification_email
}

data "archive_file" "remediation_zip" {
  type        = "zip"
  source_file = "${path.module}/remediate.py"
  output_path = "${path.module}/remediate.zip"
}

resource "aws_iam_role" "remediation_role" {
  name = "${var.project_name}-remediation-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_exec" {
  role       = aws_iam_role.remediation_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "remediation_policy" {
  name = "${var.project_name}-remediation-policy-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Remediation"
        Effect = "Allow"
        Action = [
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketPublicAccessBlock"
        ]
        Resource = "*"
      },
      {
        Sid      = "SNSPublish"
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.security_alerts.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "remediation_policy_attach" {
  role       = aws_iam_role.remediation_role.name
  policy_arn = aws_iam_policy.remediation_policy.arn
}

resource "aws_lambda_function" "remediation" {
  function_name    = "${var.project_name}-auto-remediate-${var.environment}"
  role             = aws_iam_role.remediation_role.arn
  handler          = "remediate.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.remediation_zip.output_path
  source_code_hash = data.archive_file.remediation_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.security_alerts.arn
      ENVIRONMENT   = var.environment
    }
  }
}

# EventBridge Rule triggering on AWS Config compliance changes
resource "aws_cloudwatch_event_rule" "config_compliance_change" {
  name        = "${var.project_name}-compliance-change-${var.environment}"
  description = "Captures non-compliant evaluation results from AWS Config"

  event_pattern = jsonencode({
    source      = ["aws.config"]
    detail-type = ["Config Rules Compliance Change"]
    detail = {
      newEvaluationResult = {
        complianceType = ["NON_COMPLIANT"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_remediation_target" {
  rule      = aws_cloudwatch_event_rule.config_compliance_change.name
  target_id = "TriggerRemediationLambda"
  arn       = aws_lambda_function.remediation.arn
}

resource "aws_lambda_permission" "allow_eventbridge_invoke" {
  statement_id  = "AllowEventBridgeInvokeRemediation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.remediation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.config_compliance_change.arn
}
