# LAB1 Bonus C Notes - Route53, ACM, and HTTPS

## Goal

Extend the Bonus B ALB deployment with a custom HTTPS endpoint using Route53 DNS, ACM certificate validation, and an HTTPS listener on the existing public ALB.

## Domain

- Root domain: kulturalintercessor.org
- App subdomain: app
- Final app URL: https://app.kulturalintercessor.org

## Implemented

- Confirmed Route53 hosted zone for kulturalintercessor.org
- Requested ACM certificate for app.kulturalintercessor.org
- Validated ACM certificate using Route53 DNS validation
- Added inbound HTTPS/443 rule to the ALB security group
- Added HTTPS listener on the existing ALB
- Created Route53 A ALIAS record for app.kulturalintercessor.org pointing to the ALB
- Verified HTTPS access to /health
- Verified HTTPS access to /list

## Important note

A `curl -I` request returned HTTP/2 501 because the Python app/server does not support HEAD requests. This was not treated as a Bonus C failure because normal GET requests to the HTTPS endpoint succeeded.

## Verification screenshots

Screenshots are saved under:

deliverables/screenshots/1c_bonus_c/

Included evidence:

- bonus-c-hcp-apply-success.png
- bonus-c-acm-issued.png
- bonus-c-https-listener-443.png
- bonus-c-route53-app-alias.png
- bonus-c-curl-health-https-200.png
- bonus-c-curl-list-https.png
