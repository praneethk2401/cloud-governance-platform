import boto3
import json
import os
from datetime import datetime

def lambda_handler(event, context):
    ssm = boto3.client('ssm', region_name='ap-south-2')
    s3  = boto3.client('s3',  region_name='ap-south-2')
    sns = boto3.client('sns', region_name='ap-south-2')

    environments = ['non-prod', 'prod', 'dr']
    compliance_report = {}

    # Loop through each environment and collect patch compliance data
    for env in environments:
        try:
            response = ssm.describe_instance_patch_states_for_patch_group(
                PatchGroup=env
            )
            instances = response.get('InstancePatchStates', [])

            compliant     = sum(1 for i in instances if i.get('PatchComplianceLevel') != 'NON_COMPLIANT')
            non_compliant = len(instances) - compliant

            compliance_report[env] = {
                'total_instances'      : len(instances),
                'compliant'            : compliant,
                'non_compliant'        : non_compliant,
                'compliance_percentage': round((compliant / len(instances) * 100), 2) if instances else 0,
                'instances'            : [
                    {
                        'instance_id'             : i.get('InstanceId'),
                        'patch_compliance_level'  : i.get('PatchComplianceLevel'),
                        'installed_count'         : i.get('InstalledCount', 0),
                        'missing_count'           : i.get('MissingCount', 0),
                        'failed_count'            : i.get('FailedCount', 0),
                        'last_operation'          : i.get('LastNoRebootInstallOperationTime', 'N/A')
                    }
                    for i in instances
                ]
            }

        except Exception as e:
            compliance_report[env] = {
                'error'  : str(e),
                'message': f'Could not retrieve compliance data for {env}'
            }

    # Save full report to S3
    report_key = f"patch-reports/{datetime.now().strftime('%Y-%m-%d-%H-%M')}-compliance.json"
    try:
        s3.put_object(
            Bucket=os.environ['COMPLIANCE_BUCKET'],
            Key   =report_key,
            Body  =json.dumps(compliance_report, indent=2, default=str)
        )
        print(f"Report saved to S3: {report_key}")
    except Exception as e:
        print(f"Failed to save report to S3: {str(e)}")

    # Build email summary
    summary_lines = [f"PATCH COMPLIANCE REPORT - {datetime.now().strftime('%Y-%m-%d %H:%M')}"]
    summary_lines.append("=" * 50)

    for env, data in compliance_report.items():
        if 'error' in data:
            summary_lines.append(f"{env.upper()}: Error retrieving data")
        else:
            summary_lines.append(
                f"{env.upper()}: {data['compliance_percentage']}% compliant "
                f"({data['compliant']}/{data['total_instances']} instances)"
            )
            if data['non_compliant'] > 0:
                summary_lines.append(f"  ⚠️  {data['non_compliant']} instance(s) non-compliant!")

    summary_lines.append("=" * 50)
    summary_lines.append(f"Full report saved to S3: {report_key}")

    # Send SNS notification
    try:
        sns.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Subject =f"Patch Compliance Report - {datetime.now().strftime('%Y-%m-%d')}",
            Message ="\n".join(summary_lines)
        )
        print("SNS notification sent successfully")
    except Exception as e:
        print(f"Failed to send SNS notification: {str(e)}")

    return {
        'statusCode': 200,
        'body'      : json.dumps(compliance_report, default=str)
    }