# Case study: AWS security and IAM governance

**Portfolio status:** PARTIALLY TESTED. Deployed live to AWS on 2026-09-23. The S3 public-bucket detection-and-remediation loop is verified end to end with measured timing. Other operational outcomes (AccessDenied/MFA lab, remediation behavior for the other three Config rules) remain documentation only.

## Business problem

Model a governance baseline that can detect selected AWS misconfigurations and explain IAM authorization failures. This is a portfolio lab scenario; no production compliance outcome is claimed.

## Architecture and technologies

The [root Terraform](main.tf) composes [AWS Config rules](modules/config_rules/main.tf), [IAM Access Analyzer](modules/iam_analyzer/main.tf), [IAM groups and an MFA policy](modules/iam_governance/main.tf), and an [EventBridge/Lambda remediation path](modules/remediation_engine/main.tf). A [Python audit script](scripts/audit_iam_permissions.py) supports permission review.

## What is implemented

The code defines a Config recorder and selected managed rules, IAM groups, an analyzer, and a Lambda intended to respond to noncompliance events. A live lab verified the S3 public-read path: Config flagged a deliberately public test bucket `NON_COMPLIANT` in 2m 43s, EventBridge invoked the remediation Lambda, the Lambda re-blocked public access, and anonymous access afterward returned `403`. It does not yet prove broad CIS compliance, and one bug surfaced during the lab: the Lambda logs "Triggering automated remediation..." for every non-compliant event it receives, even for rules its remediation branch does not actually act on (confirmed for `s3-bucket-ssl-requests-only`) — a log reader could mistake that line for a completed fix.

## Failure modes and runbooks

The [IAM AccessDenied runbook](https://github.com/TreyWright360/aws-cloud-operations-handbook/blob/main/security/iam-access-denied.md) walks through principal, action, resource, identity policy, resource policy, boundary, session policy, and organization policy. The [failure map](https://github.com/TreyWright360/aws-cloud-operations-handbook/blob/main/architecture/master-failure-map.md) includes IAM and S3 denial scenarios.

## Test evidence and video

**PARTIALLY TESTED.** The S3 public-bucket detection-and-remediation loop has [dated evidence](https://github.com/TreyWright360/aws-cloud-operations-handbook/blob/main/evidence/s3-public-remediation/INDEX.md) with a measured detection time and a post-fix `403` validation. The AccessDenied/MFA lab is still **DOCUMENTATION ONLY** — no redacted denied request, policy evaluation, correction, successful retry, or incident video is checked in yet. A lab should use a disposable role and harmless read action.

## Security and cost controls

The Config log bucket enables encryption and public access block. The remediation Lambda policy currently grants S3 public-access-block actions on `*`; the developer group has managed `PowerUserAccess`. Those scopes need review before production use. Config recording, Lambda, S3, and notifications can incur charges.

## Production improvements

Prove rule coverage against current control definitions, scope IAM resources more narrowly, validate the Lambda event pattern, test remediation and rollback, add alarm ownership, and record measured detection and correction times.

## CI/CD and deployment validation

- **CI status:** Verified passing without AWS credentials or terraform apply on PR and main push.
- **PR validation run:** [Run #35786777600](https://github.com/TreyWright360/aws-cloud-security-iam-governance/actions/runs/35786777600) (passed)
- **Main branch validation run:** [Run #35786847850](https://github.com/TreyWright360/aws-cloud-security-iam-governance/actions/runs/35786847850) (passed, non-deploying)
- **Deployment safeguards:** Automatic deployment is removed from push to `main`. Deployment is isolated in `.github/workflows/deploy-production.yml`, requiring manual `workflow_dispatch` trigger and approval via the protected `production` environment.


