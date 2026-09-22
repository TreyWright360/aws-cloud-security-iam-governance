# Case study: AWS security and IAM governance

**Portfolio status:** Terraform and audit code published; operational outcomes are documentation only.

## Business problem

Model a governance baseline that can detect selected AWS misconfigurations and explain IAM authorization failures. This is a portfolio lab scenario; no production compliance outcome is claimed.

## Architecture and technologies

The [root Terraform](main.tf) composes [AWS Config rules](modules/config_rules/main.tf), [IAM Access Analyzer](modules/iam_analyzer/main.tf), [IAM groups and an MFA policy](modules/iam_governance/main.tf), and an [EventBridge/Lambda remediation path](modules/remediation_engine/main.tf). A [Python audit script](scripts/audit_iam_permissions.py) supports permission review.

## What is implemented

The code defines a Config recorder and selected managed rules, IAM groups, an analyzer, and a Lambda intended to respond to noncompliance events. It does not prove broad CIS compliance or that a remediation event completed in AWS.

## Failure modes and runbooks

The [IAM AccessDenied runbook](https://github.com/TreyWright360/aws-cloud-operations-handbook/blob/main/security/iam-access-denied.md) walks through principal, action, resource, identity policy, resource policy, boundary, session policy, and organization policy. The [failure map](https://github.com/TreyWright360/aws-cloud-operations-handbook/blob/main/architecture/master-failure-map.md) includes IAM and S3 denial scenarios.

## Test evidence and video

**DOCUMENTATION ONLY.** No redacted denied request, policy evaluation, correction, successful retry, or incident video is checked in. A lab should use a disposable role and harmless read action.

## Security and cost controls

The Config log bucket enables encryption and public access block. The remediation Lambda policy currently grants S3 public-access-block actions on `*`; the developer group has managed `PowerUserAccess`. Those scopes need review before production use. Config recording, Lambda, S3, and notifications can incur charges.

## Production improvements

Prove rule coverage against current control definitions, scope IAM resources more narrowly, validate the Lambda event pattern, test remediation and rollback, add alarm ownership, and record measured detection and correction times.

## CI/CD and deployment validation

- **CI status:** Verified passing without AWS credentials or terraform apply on PR and main push.
- **PR validation run:** [Run #35786777600](https://github.com/TreyWright360/aws-cloud-security-iam-governance/actions/runs/35786777600) (passed)
- **Main branch validation run:** [Run #35786847850](https://github.com/TreyWright360/aws-cloud-security-iam-governance/actions/runs/35786847850) (passed, non-deploying)
- **Deployment safeguards:** Automatic deployment is removed from push to `main`. Deployment is isolated in `.github/workflows/deploy-production.yml`, requiring manual `workflow_dispatch` trigger and approval via the protected `production` environment.


