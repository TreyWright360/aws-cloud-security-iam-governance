# Enterprise Cloud Security, IAM Governance & Technical Debt Remediation

[![Terraform](https://img.shields.io/badge/IaC-Terraform_1.8+-623CE4.svg?logo=terraform)](https://www.terraform.io)
[![CIS Benchmark](https://img.shields.io/badge/Compliance-CIS_AWS_v3.0-007ACC.svg)](https://www.cisecurity.org)
[![AWS](https://img.shields.io/badge/AWS-Security_Governance-FF9900.svg?logo=amazon-aws)](https://aws.amazon.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A production-grade cloud security governance framework, automated compliance monitoring engine, and IAM technical debt remediation codebase built on AWS using modular Terraform. Modeled after real enterprise consulting cleanups (remediating 5+ years of unmanaged startup permissions debt), this system establishes continuous compliance against the **CIS AWS Foundations Benchmark v3.0**, detects public resource exposure via **IAM Access Analyzer**, and executes real-time event-driven remediation via **Amazon EventBridge** and **AWS Lambda**.

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

## 🛡️ CIS AWS Foundations Benchmark v3.0 Mapping

| CIS Benchmark Control | AWS Service Implementation | Remediation Mechanism |
| :--- | :--- | :--- |
| **1.5 (Level 1):** Ensure MFA is enabled for all IAM users | IAM Governance Group Policy | Denies all AWS API access if `aws:MultiFactorAuthPresent` is false. |
| **1.16 (Level 1):** Ensure IAM policies are attached only to groups/roles | IAM Governance Module | Prohibits direct user-level inline policy attachments. |
| **2.1.1 (Level 2):** Ensure S3 Bucket Public Access Block is enabled | AWS Config Rule + Lambda | EventBridge captures `NON_COMPLIANT` event and triggers Lambda `put_public_access_block`. |
| **2.1.2 (Level 2):** Ensure S3 Bucket Policies require SSL/TLS | AWS Config Rule | Blocks unencrypted HTTP traffic across all storage buckets. |
| **2.2.1 (Level 1):** Ensure EBS volume encryption is enabled | AWS Config Rule | Evaluates all attached EBS volumes for KMS encryption. |

---

## 🏛️ Architecture Decision Records (ADRs)

* **ADR 001: Event-Driven Serverless Auto-Remediation vs. Periodic Cron Scanning**
  * *Decision:* Implemented EventBridge integration with AWS Config rules over scheduled cron scripts.
  * *Rationale:* Event-driven remediation reduces mean time to remediation (MTTR) from hours down to sub-10 seconds for critical misconfigurations like public S3 buckets.
* **ADR 002: Deny-All Conditional Policy for MFA Enforcement**
  * *Decision:* Applied a global `Deny` policy on all actions except MFA configuration if MFA is absent.
  * *Rationale:* Guarantees users cannot execute any production commands or access sensitive data until physical or virtual MFA is validated.
* **ADR 003: IAM Access Analyzer for Continuous External Exposure Tracking**
  * *Decision:* Deployed account-level IAM Access Analyzer.
  * *Rationale:* Automatically detects cross-account IAM trust policies, public KMS keys, and open S3 buckets using formal logic mathematical reasoning.

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
terraform apply -var-file="environments/prod.tfvars" -auto-approve
```
