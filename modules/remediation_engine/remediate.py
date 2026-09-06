import json
import os
import boto3

s3_client = boto3.client("s3")
sns_client = boto3.client("sns")

SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")

def lambda_handler(event, context):
    """
    Automated Remediation Engine: triggered on AWS Config non-compliant evaluations.
    Automatically remediates public S3 buckets and sends security alerts via SNS.
    """
    print("Received event:", json.dumps(event))
    detail = event.get("detail", {})
    resource_id = detail.get("resourceId")
    resource_type = detail.get("resourceType")
    compliance_type = detail.get("newEvaluationResult", {}).get("complianceType")
    rule_name = detail.get("configRuleName")

    if compliance_type == "NON_COMPLIANT":
        message = f"🚨 CRITICAL SECURITY ALERT: Non-compliant resource detected!\nRule: {rule_name}\nResource: {resource_id} ({resource_type})\nTriggering automated remediation..."
        print(message)

        # Auto-remediation for S3 Public Access Block
        if resource_type == "AWS::S3::Bucket" and "public" in rule_name.lower():
            try:
                print(f"Applying strict Public Access Block to S3 bucket: {resource_id}")
                s3_client.put_public_access_block(
                    Bucket=resource_id,
                    PublicAccessBlockConfiguration={
                        "BlockPublicAcls": True,
                        "IgnorePublicAcls": True,
                        "BlockPublicPolicy": True,
                        "RestrictPublicBuckets": True
                    }
                )
                message += f"\n✅ REMEDIATION SUCCESSFUL: Strict S3 Public Access Block applied to {resource_id}."
            except Exception as e:
                message += f"\n❌ REMEDIATION FAILED: {str(e)}"

        # Publish notification to Security SNS Topic
        if SNS_TOPIC_ARN:
            try:
                sns_client.publish(
                    TopicArn=SNS_TOPIC_ARN,
                    Subject=f"[Security Alert] Automated Remediation for {resource_id}",
                    Message=message
                )
            except Exception as e:
                print("Failed to publish SNS notification:", str(e))

    return {
        "statusCode": 200,
        "body": json.dumps({"status": "Evaluation processed."})
    }
