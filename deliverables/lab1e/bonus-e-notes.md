# LAB1 Bonus E - AWS WAF Logging

## Completed

- Added AWS WAF logging for the existing LAB1 regional Web ACL.
- Created a CloudWatch Logs log group using the required `aws-waf-logs-*` naming pattern.
- Attached `aws_wafv2_web_acl_logging_configuration` to the existing WAF Web ACL.
- Verified the WAF logging configuration with AWS CLI.
- Verified the CloudWatch log group exists.
- Generated HTTPS traffic through the apex domain.
- Verified WAF log streams/events are being delivered to CloudWatch Logs.

## Key values

- WAF Web ACL: lab1-dev-waf
- WAF scope: REGIONAL
- Log destination: CloudWatch Logs
- Log group: aws-waf-logs-lab1-dev
- Retention: 14 days
- Terraform resource: aws_wafv2_web_acl_logging_configuration.app

## Verification commands used

aws wafv2 get-logging-configuration --region us-east-1 --resource-arn "$WAF_ARN"

aws logs describe-log-groups --region us-east-1 --log-group-name-prefix aws-waf-logs-lab1-dev

aws logs describe-log-streams --region us-east-1 --log-group-name aws-waf-logs-lab1-dev

aws logs filter-log-events --region us-east-1 --log-group-name aws-waf-logs-lab1-dev --limit 3
