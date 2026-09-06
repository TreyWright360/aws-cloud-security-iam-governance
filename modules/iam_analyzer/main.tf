resource "aws_accessanalyzer_analyzer" "account_analyzer" {
  analyzer_name = "${var.project_name}-analyzer-${var.environment}"
  type          = "ACCOUNT"

  tags = {
    Name = "${var.project_name}-analyzer"
  }
}
