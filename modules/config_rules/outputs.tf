output "config_recorder_id" { value = aws_config_configuration_recorder.recorder.id }
output "config_logs_bucket" { value = aws_s3_bucket.config_logs.id }
