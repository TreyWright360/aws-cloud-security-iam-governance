# Enforces MFA for all privileged group actions
data "aws_iam_policy_document" "enforce_mfa" {
  statement {
    sid    = "BlockAllWithoutMFA"
    effect = "Deny"
    not_actions = [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:GetUser",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ResyncMFADevice",
      "sts:GetSessionToken"
    ]
    resources = ["*"]
    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

resource "aws_iam_group" "security_auditors" {
  name = "${var.project_name}-security-auditors"
}

resource "aws_iam_group_policy_attachment" "auditor_readonly" {
  group      = aws_iam_group.security_auditors.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

resource "aws_iam_group" "cloud_developers" {
  name = "${var.project_name}-cloud-developers"
}

resource "aws_iam_group_policy_attachment" "dev_poweruser" {
  group      = aws_iam_group.cloud_developers.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_policy" "mfa_enforcement" {
  name        = "${var.project_name}-enforce-mfa"
  description = "Denies all API access if MFA is not authenticated"
  policy      = data.aws_iam_policy_document.enforce_mfa.json
}

resource "aws_iam_group_policy_attachment" "dev_mfa_attach" {
  group      = aws_iam_group.cloud_developers.name
  policy_arn = aws_iam_policy.mfa_enforcement.arn
}
