# LAB1 — Lab 1C Deliverable Notes

## Section

Lab 1C — CloudWatch Alarm Notification with SNS

## Repository

GitHub repository:
https://github.com/KXJohnson/lab1-ec2-rds

Local repository path:
~/Code/lab1-ec2-rds

HCP Terraform:
- Organization: ragejournal0k
- Workspace: lab1-ec2-rds
- Working directory: terraform/environments/dev
- Branch: main

## Infrastructure Context

Existing EC2 application instance:
- Name: lab1-dev-ec2-app
- InstanceId: i-0745e0cb6fb71ed51
- Public IP: 44.211.50.154
- Private IP: 10.0.1.42
- Instance profile: lab1-dev-ec2-instance-profile
- EC2 role: lab1-dev-ec2-role

Actual systemd service name:
- lab1-app.service

Important correction:
- Do not use lab-rds-app.service.

Access method:
- EC2 has no SSH key pair.
- AWS Systems Manager Session Manager is used for shell access.
- Session Manager command:
  aws ssm start-session --region us-east-1 --target i-0745e0cb6fb71ed51

## Lab 1C Terraform Changes

Lab 1C added SNS email notification support to the existing CloudWatch alarm.

Modified files:
- terraform/environments/dev/1b_ec2_cloudwatch.tf
- terraform/environments/dev/locals.tf
- terraform/environments/dev/terraform.tfvars.example
- terraform/environments/dev/variables.tf

Added Terraform local:
- sns_topic_name = "${local.name_prefix}-app-alerts"

Added Terraform variable:
- alarm_notification_email
- type = string
- sensitive = true

Added SNS resources:
- aws_sns_topic.app_alerts
- aws_sns_topic_subscription.app_alerts_email

Updated existing CloudWatch alarm:
- aws_cloudwatch_metric_alarm.ec2_app_failures

The alarm now includes:
- alarm_actions = [aws_sns_topic.app_alerts.arn]

## HCP Terraform Variable

Added HCP Terraform variable:
- Key: alarm_notification_email
- Value: rage.journal.0k@icloud.com
- Category: Terraform variable
- Sensitive: checked

## Local Validation

Local validation commands:
- terraform -chdir=terraform/environments/dev fmt
- terraform -chdir=terraform/environments/dev fmt -check
- terraform -chdir=terraform/environments/dev validate

Validation result:
- Success! The configuration is valid.

## Git Commit

Commit used for Lab 1C SNS changes:
- ef4479b Add SNS alarm notifications for Lab 1C

Push target:
- origin/main

## HCP Terraform Plan and Apply

HCP Terraform plan result:
- 2 to add, 1 to change, 0 to destroy

Resources added:
- aws_sns_topic.app_alerts
- aws_sns_topic_subscription.app_alerts_email

Resource changed:
- aws_cloudwatch_metric_alarm.ec2_app_failures

HCP Terraform apply result:
- 2 added, 1 changed, 0 destroyed

The existing CloudWatch alarm was updated in place.

## SNS Verification

SNS subscription verification showed:
- Endpoint: rage.journal.0k@icloud.com
- Protocol: email
- SubscriptionArn: real ARN, not PendingConfirmation
- TopicArn: arn:aws:sns:us-east-1:183295437238:lab1-dev-app-alerts

This confirms the email subscription was confirmed successfully.

## CloudWatch Alarm Verification

CloudWatch alarm verification showed:
- AlarmName: lab1-dev-app-failure-alarm
- StateValue: OK
- AlarmActions: arn:aws:sns:us-east-1:183295437238:lab1-dev-app-alerts

This confirms the CloudWatch alarm is connected to the SNS topic.

## Screenshot Evidence

Screenshots are stored in:
- deliverables/screenshots/1c_base/

Screenshot files:
- deliverables/screenshots/1c_base/lab1c-cloudwatch-alarm-actions-sns.png
- deliverables/screenshots/1c_base/lab1c-hcp-apply-sns-2-added-1-changed.png
- deliverables/screenshots/1c_base/lab1c-hcp-plan-sns-2-add-1-change.png
- deliverables/screenshots/1c_base/lab1c-sns-email-subscription-confirmed.png

## Lab 1C Completion Summary

Lab 1C successfully added SNS-based email notification to the existing CloudWatch alarm.

The alarm now sends notifications through:
- arn:aws:sns:us-east-1:183295437238:lab1-dev-app-alerts

The SNS email subscription is confirmed, and the existing CloudWatch alarm is configured with the SNS topic ARN as an alarm action.
