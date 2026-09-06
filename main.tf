# Root Configuration - Enterprise Cloud Security, IAM Governance & Automated Remediation

module "config_rules" {
  source       = "./modules/config_rules"
  project_name = var.project_name
  environment  = var.environment
}

module "iam_analyzer" {
  source       = "./modules/iam_analyzer"
  project_name = var.project_name
  environment  = var.environment
}

module "remediation_engine" {
  source                      = "./modules/remediation_engine"
  project_name                = var.project_name
  environment                 = var.environment
  security_notification_email = var.security_notification_email
}

module "iam_governance" {
  source       = "./modules/iam_governance"
  project_name = var.project_name
  environment  = var.environment
}
