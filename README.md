# Enterprise Cloud Security, IAM Governance & Technical Debt Remediation

> **Portfolio evidence status:** The Terraform and audit script are published; no dated AccessDenied lab or production remediation record is checked in. Use the [IAM AccessDenied runbook](https://github.com/TreyWright360/aws-cloud-operations-handbook/blob/main/security/iam-access-denied.md) and [duty map](https://github.com/TreyWright360/aws-cloud-operations-handbook/blob/main/DUTY-MAP.md) to see the intended operational proof.

[![Terraform](https://img.shields.io/badge/IaC-Terraform_1.8+-623CE4.svg?logo=terraform)](https://www.terraform.io)
[![CIS Benchmark](https://img.shields.io/badge/Compliance-CIS_AWS_v3.0-007ACC.svg)](https://www.cisecurity.org)
[![AWS](https://img.shields.io/badge/AWS-Security_Governance-FF9900.svg?logo=amazon-aws)](https://aws.amazon.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This repository contains a modular Terraform design for AWS Config rules, IAM Access Analyzer, IAM governance, and EventBridge/Lambda remediation, plus a Python IAM audit script. The design is a portfolio lab; deployment, control coverage, response time, and compliance outcomes need separate evidence before they are presented as measured results.

---

## 🏗️ Architectural Topology

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                 ENTERPRISE SECURITY GOVERNANCE TOPOLOGY                     │
└─────────────────────────────────────────────────────────────────────────────┘

 [ AWS Environment Resources ]
    (S3, IAM, EBS, KMS)
              │
              ▼
 ┌─────────────────────────┐
 │   AWS Config Recorder   │ ──(Evaluates Conformance Packs / Rules)──┐
 └────────────┬────────────┘                                         │
              │                                                      │
              ▼ (Non-Compliant Change Detected)                      │
 ┌─────────────────────────┐                                         │
 │    Amazon EventBridge   │                                         ▼
 └────────────┬────────────┘                              ┌─────────────────────┐
              │                                           │ IAM Access Analyzer │
              ▼                                           │ (Finds External /   │
 ┌─────────────────────────┐                              │  Public Grants)     │
 │  Auto-Remediation Lambda│                              └─────────────────────┘
 └────────────┬────────────┘
              │
      ┌───────┴────────────────────────┐
      ▼                                ▼
┌─────────────────────────┐    ┌─────────────────────────┐
│ Apply S3 Block Public   │    │  Amazon SNS Topic       │
│ Access / Restrict ACLs  │    │ (Alerts Security Team)  │
└─────────────────────────┘    └─────────────────────────┘
```

---

## 🛡️ Implemented controls and validation gaps

| Area | Current code | Validation gap |
| :--- | :--- | :--- |
| MFA | A deny policy is attached to the `cloud_developers` group | It does not cover every IAM user or prove MFA was enforced in a lab |
| IAM attachment | Auditor and developer groups have managed policy attachments | The module does not prohibit all direct user policy attachments |
| S3 public read | AWS Config rule and remediation Lambda are defined | Capture a noncompliant event, Lambda execution, and corrected bucket state |
| S3 TLS | `S3_BUCKET_SSL_REQUESTS_ONLY` Config rule is defined | It evaluates policy compliance; the rule itself does not block HTTP requests |
| EBS encryption | `ENCRYPTED_VOLUMES` Config rule is defined | Capture evaluation results and identify remediation ownership |

---

## 🏛️ Architecture Decision Records (ADRs)

* **ADR 001: Event-Driven Serverless Auto-Remediation vs. Periodic Cron Scanning**
  * *Decision:* Implemented EventBridge integration with AWS Config rules over scheduled cron scripts.
  * *Rationale:* Event-driven remediation can reduce detection-to-action time; this repository does not include a measured MTTR.
* **ADR 002: Deny-All Conditional Policy for MFA Enforcement**
  * *Decision:* Applied a global `Deny` policy on all actions except MFA configuration if MFA is absent.
  * *Rationale:* Adds an MFA condition for members of the developer group; verify the exact policy effect and exclusions before relying on it for production access control.
* **ADR 003: IAM Access Analyzer for Continuous External Exposure Tracking**
  * *Decision:* Deployed account-level IAM Access Analyzer.
  * *Rationale:* Access Analyzer can identify external access findings; inspect the analyzer scope and supported resource types in the deployed account.

---

## 🚀 Quickstart Deployment & Security Audit

### 1. Run the Python IAM Technical Debt Scanner
```bash
python3 scripts/audit_iam_permissions.py
```

### 2. Deploy Automated Governance Baseline via Terraform
```bash
# Initialize Terraform
terraform init

# Review execution plan
terraform plan -var-file="environments/prod.tfvars"

# Apply governance controls
terraform apply -var-file="environments/dev.tfvars"
```
