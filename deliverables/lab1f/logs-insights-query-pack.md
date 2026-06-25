# LAB1 Bonus F - CloudWatch Logs Insights Query Pack

## Purpose

This query pack documents reusable CloudWatch Logs Insights queries for LAB1 incident review, WAF analysis, application troubleshooting, and recovery verification.

## Log groups

- App log group: /aws/ec2/lab1-dev-app
- WAF log group: aws-waf-logs-lab1-dev

---

## Query 1 - WAF recent requests

Log group: aws-waf-logs-lab1-dev

Query:

    fields @timestamp, action, httpRequest.clientIp, httpRequest.country, httpRequest.httpMethod, httpRequest.uri, terminatingRuleId
    | sort @timestamp desc
    | limit 25

Purpose:

Shows recent WAF-evaluated requests, including action, source IP, country, HTTP method, URI, and terminating rule.

Screenshot:

    deliverables/screenshots/1c_bonus_f/waf-recent-requests.png

---

## Query 2 - WAF actions summary

Log group: aws-waf-logs-lab1-dev

Query:

    fields action
    | stats count(*) as request_count by action
    | sort request_count desc

Purpose:

Summarizes WAF request outcomes such as ALLOW, BLOCK, COUNT, CAPTCHA, or CHALLENGE.

Screenshot:

    deliverables/screenshots/1c_bonus_f/waf-actions-summary.png

---

## Query 3 - WAF top client IPs

Log group: aws-waf-logs-lab1-dev

Query:

    fields httpRequest.clientIp
    | stats count(*) as request_count by httpRequest.clientIp
    | sort request_count desc
    | limit 10

Purpose:

Identifies the most frequent client IP addresses seen by WAF.

Screenshot:

    deliverables/screenshots/1c_bonus_f/waf-top-client-ips.png

---

## Query 4 - App recent logs

Log group: /aws/ec2/lab1-dev-app

Query:

    fields @timestamp, @message
    | sort @timestamp desc
    | limit 25

Purpose:

Shows recent application log messages for operational review and service verification.

Screenshot:

    deliverables/screenshots/1c_bonus_f/app-recent-logs.png

---

## Query 5 - App errors or failures

Log group: /aws/ec2/lab1-dev-app

Query:

    fields @timestamp, @message
    | filter @message like /error|ERROR|failed|FAILED|failure|FAILURE|exception|Exception/
    | sort @timestamp desc
    | limit 25

Purpose:

Searches application logs for common error, failure, and exception patterns.

Screenshot:

    deliverables/screenshots/1c_bonus_f/app-error-search.png

---

## Verification completed

- Ran all queries in the AWS CloudWatch Logs Insights Console.
- Captured screenshots for each query and result set.
- Stored screenshots in deliverables/screenshots/1c_bonus_f/.
- Stored this query pack in deliverables/lab1f/logs-insights-query-pack.md.
