# Lab 1b — Incident Response Summary

## Environment

- Repo: https://github.com/KXJohnson/lab1-ec2-rds
- HCP Terraform organization: ragejournal0k
- HCP Terraform workspace: lab1-ec2-rds
- HCP Terraform working directory: terraform/environments/dev
- AWS region: us-east-1

## EC2 Application Host

- Name: lab1-dev-ec2-app
- InstanceId: i-0745e0cb6fb71ed51
- Public IP: 44.211.50.154
- Private IP: 10.0.1.42
- Public DNS: ec2-44-211-50-154.compute-1.amazonaws.com
- Instance profile: lab1-dev-ec2-instance-profile
- EC2 role: lab1-dev-ec2-role
- SSH key pair: None
- Access method: AWS Systems Manager Session Manager

## Application Service

- Correct service name: lab1-app.service
- Incorrect service name to avoid: lab-rds-app.service

## Incident Simulation

A database credential failure was simulated by temporarily changing only the password field in AWS Secrets Manager for:

- Secret name: lab/rds/mysql

This caused the EC2 application to fail database authentication while leaving the EC2 instance and RDS instance deployed.

## Detection Evidence

CloudWatch Logs showed application-level database failure entries, including:

- ERROR LAB1_APP_ERROR secret_or_db_validation_failed
- error_type=OperationalError
- Database credential authentication failure

## Alarm Evidence

CloudWatch alarm:

- Alarm name: lab1-dev-app-failure-alarm
- Metric: lab1-dev-app-failures
- Namespace: LAB1/EC2App
- Threshold: 1.0
- Period: 300
- EvaluationPeriods: 1

Alarm history showed repeated state transitions:

- OK to ALARM during the simulated failure
- ALARM to OK after recovery

Relevant entries included:

- 2026-06-04T04:16:27... Alarm updated from OK to ALARM
- 2026-06-04T04:45:27... Alarm updated from ALARM to OK

Screenshot:

- lab1b-7.6-cloudwatch-alarm-history.png

Caption:

Lab 1b — 7.6: CloudWatch alarm history shows the LAB1 application failure alarm transitioning from OK to ALARM during the simulated DB connection failure and returning to OK after recovery.

## Recovery Evidence

After restoring the correct database credential value in Secrets Manager, the application recovered without redeploying EC2.

Command used:

curl -i http://44.211.50.154/list

Result:

HTTP/1.1 200 OK

Screenshot:

- lab1b-7.7-incident-recovery-curl-list.png

Caption:

Lab 1b — 7.7: Incident recovery verification shows the EC2 application successfully responding from the /list endpoint after the simulated database credential failure was restored, proving recovery without redeploying EC2.

## Operational Conclusion

This incident-response workflow proves that the LAB1 system can detect a database credential failure through CloudWatch Logs and a CloudWatch alarm, then recover by restoring the correct secret value without rebuilding or redeploying the EC2 application server.
