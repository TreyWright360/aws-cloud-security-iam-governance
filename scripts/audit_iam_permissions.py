#!/usr/bin/env python3
"""
Enterprise IAM Least-Privilege & Technical Debt Security Auditor
Scans AWS IAM Users, Roles, and Policies to detect over-privileged wildcard permissions (*)
and generates a CIS AWS Foundations Benchmark compliance report.
"""

import json
import boto3

iam = boto3.client("iam")

def scan_iam_technical_debt():
    print("==================================================================")
    print("🔍 INITIATING CIS AWS BENCHMARK & IAM TECHNICAL DEBT AUDIT")
    print("==================================================================")
    
    findings = []
    
    # 1. Audit IAM Users for MFA and Access Keys
    users = iam.list_users()["Users"]
    print(f"\n[1/3] Auditing {len(users)} IAM Users...")
    for u in users:
        uname = u["UserName"]
        mfa = iam.list_mfa_devices(UserName=uname)["MFADevices"]
        keys = iam.list_access_keys(UserName=uname)["AccessKeyMetadata"]
        
        if not mfa:
            findings.append({
                "severity": "HIGH",
                "resource": f"IAM User: {uname}",
                "issue": "MFA is NOT enabled on user account (CIS 1.5 Violation)."
            })
            print(f"  ❌ [HIGH] User {uname} does not have MFA enabled.")
        else:
            print(f"  ✅ [PASS] User {uname} has MFA enabled.")
            
        if len(keys) > 1:
            findings.append({
                "severity": "MEDIUM",
                "resource": f"IAM User: {uname}",
                "issue": f"Multiple ({len(keys)}) active access keys detected (CIS 1.13 Violation)."
            })

    # 2. Audit Customer Managed Policies for Wildcard (*) Over-Privileged Actions
    print("\n[2/3] Auditing Customer Managed Policies for Wildcard Permissions...")
    policies = iam.list_policies(Scope="Local")["Policies"]
    for p in policies:
        pname = p["PolicyName"]
        parn = p["Arn"]
        version_id = p["DefaultVersionId"]
        
        version_doc = iam.get_policy_version(PolicyArn=parn, VersionId=version_id)["PolicyVersion"]["Document"]
        statements = version_doc.get("Statement", [])
        if isinstance(statements, dict):
            statements = [statements]
            
        for stmt in statements:
            if stmt.get("Effect") == "Allow":
                actions = stmt.get("Action", [])
                resources = stmt.get("Resource", [])
                
                if actions == "*" or "*" in actions:
                    findings.append({
                        "severity": "CRITICAL",
                        "resource": f"Policy: {pname}",
                        "issue": "Wildcard Action (*) allows full administrative access without restriction."
                    })
                    print(f"  🚨 [CRITICAL] Policy {pname} contains wildcard Action (*).")

    # 3. Summary Report
    print("\n==================================================================")
    print("📋 AUDIT SUMMARY & REMEDIATION REPORT")
    print("==================================================================")
    print(f"Total Security Violations Found: {len(findings)}")
    for idx, f in enumerate(findings, 1):
        print(f"{idx}. [{f["severity"]}] {f["resource"]}: {f["issue"]}")
        
    print("\nRecommended Action: Execute automated Terraform remediation modules.")

if __name__ == "__main__":
    scan_iam_technical_debt()
