# LAB1 Bonus B Notes

## Summary

Bonus B extended the LAB1 environment by placing the private EC2 application behind an Application Load Balancer, protecting the ALB with AWS WAF, adding CloudWatch dashboard visibility, and creating an ALB 5xx CloudWatch alarm connected to the existing Lab 1C SNS alert topic.

## Completed Components

- Added second public subnet required for the Application Load Balancer.
- Created Application Load Balancer and target group for the private EC2 app.
- Verified ALB returned HTTP 200 for `/health` and `/list`.
- Added AWS WAF Web ACL and associated it with the ALB.
- Verified the ALB still returned HTTP 200 through WAF.
- Created CloudWatch dashboard for Bonus B visibility.
- Added CloudWatch alarm for ALB 5xx errors.
- Reused the existing Lab 1C SNS topic for alarm and OK notifications.
- Verified the ALB 5xx alarm exists through AWS CLI.
- Performed non-destructive manual alarm-state validation and returned alarm to OK.

## Key Resources

- ALB DNS: lab1-dev-alb-908265993.us-east-1.elb.amazonaws.com
- Private EC2 instance: i-088c34f25fbe000ec
- EC2 service: lab1-app.service
- ALB 5xx alarm: lab1-dev-alb-5xx-errors
- SNS topic: lab1-dev-app-alerts

## Validation Evidence

Screenshots are saved under:

`deliverables/screenshots/1c_bonus_b/`

Key screenshots include:

- `alb-health-200.png`
- `alb-list-200.png`
- `hcp-bonus-b-alb-foundation-apply.png`
- `waf-alb-health-200.png`
- `waf-alb-list-200.png`
- `cloudwatch-dashboard-list.png`
- `cloudwatch-dashboard-bonus-b.png`
- `hcp-bonus-b-alb-5xx-alarm-apply.png`
- `alb-5xx-alarm-cli-verified.png`
- `alb-5xx-alarm-manual-alarm-state.png`
- `alb-5xx-alarm-returned-ok.png`

## Non-Destructive Alarm Validation

The ALB 5xx alarm was validated by manually setting the CloudWatch alarm state to `ALARM`, confirming the state change, then returning the alarm to `OK`. This avoided intentionally breaking the application, ALB, WAF, EC2, or RDS resources.
