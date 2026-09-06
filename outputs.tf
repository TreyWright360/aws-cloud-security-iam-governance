output "config_recorder_id" {
  description = "AWS Config Configuration Recorder ID"
  value       = module.config_rules.config_recorder_id
}

output "access_analyzer_arn" {
  description = "IAM Access Analyzer ARN"
  value       = module.iam_analyzer.analyzer_arn
}

output "security_alerts_sns_topic_arn" {
  description = "SNS Topic ARN for security compliance alerts"
  value       = module.remediation_engine.sns_topic_arn
}

output "remediation_lambda_name" {
  description = "Name of the automated remediation Lambda function"
  value       = module.remediation_engine.remediation_lambda_name
}
