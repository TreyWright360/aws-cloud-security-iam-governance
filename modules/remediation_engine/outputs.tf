output "sns_topic_arn" { value = aws_sns_topic.security_alerts.arn }
output "remediation_lambda_name" { value = aws_lambda_function.remediation.function_name }
