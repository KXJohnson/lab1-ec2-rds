# LAB1 Bonus D - Apex Route53 ALIAS + ALB Access Logs

## Completed

- Added apex Route53 A ALIAS record for kulturalintercessor.org pointing to the existing LAB1 ALB.
- Updated ACM certificate coverage so HTTPS works for the apex domain.
- Enabled ALB access logging on the existing Application Load Balancer.
- Created S3 bucket for ALB access logs.
- Added required S3 bucket policy for Elastic Load Balancing log delivery.
- Verified apex DNS resolution.
- Verified HTTPS access to /health with GET 200.
- Verified HTTPS access to /list.
- Verified ALB access logging attributes:
  - access_logs.s3.enabled = true
  - access_logs.s3.bucket = lab1-dev-alb-logs-183295437238
  - access_logs.s3.prefix = alb-access-logs
- Verified ALB log objects were delivered to S3.

## Key values

- Apex URL: https://kulturalintercessor.org
- App URL: https://app.kulturalintercessor.org
- ALB logs bucket: lab1-dev-alb-logs-183295437238
- ALB logs prefix: alb-access-logs
- EC2 remains private with no public IP and SSM-only access.
