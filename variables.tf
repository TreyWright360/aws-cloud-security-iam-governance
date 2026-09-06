variable "aws_region" {
  description = "AWS Region to deploy security governance resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name identifier"
  type        = string
  default     = "enterprise-security-governance"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "security_notification_email" {
  description = "Security operations email for critical compliance alert notifications"
  type        = string
  default     = "security-ops@example.com"
}
