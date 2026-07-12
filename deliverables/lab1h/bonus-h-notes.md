# LAB1 Bonus H - Bedrock Auto-Generated Incident Reports

## Official Requirement

When an alarm fires, automatically:

1. Collect alarm metadata, Logs Insights evidence, SSM params, and Secrets Manager metadata.
2. Generate a structured Markdown incident report using Amazon Bedrock Runtime.
3. Store both evidence JSON and human report Markdown in S3.
4. Notify the on-call engineer through SNS.

## Implementation Summary

- Updated the existing `lab1-dev-incident-reporter` Lambda to satisfy Bonus H.
- Lambda is subscribed to the existing LAB1 alarm SNS topic.
- Lambda collects:
  - CloudWatch alarm metadata from the SNS alarm message.
  - CloudWatch Logs Insights evidence from the app log group.
  - CloudWatch Logs Insights evidence from the WAF log group.
  - SSM Parameter Store recovery values under `/lab/db/`.
  - Secrets Manager metadata only, using `DescribeSecret`.
- Lambda generates the human-readable Markdown report using Amazon Bedrock Runtime.
- Lambda stores both required S3 objects under `reports/`.
- Lambda publishes a report-ready notification to the existing incident report SNS topic.

## Bedrock Model Used

The implementation uses Amazon Nova Lite through Bedrock Runtime Converse:

- Model ID: `us.amazon.nova-lite-v1:0`
- Runtime API path: `bedrock.converse`

This was used to avoid Anthropic Marketplace/model-access subscription friction while still satisfying the requirement to generate the report through Amazon Bedrock Runtime.

## Required S3 Objects Verified

Final incident ID:

- `lab1-incident-20260707T101045Z`

Required objects:

- `s3://lab1-dev-incident-reports-183295437238/reports/lab1-incident-20260707T101045Z.json`
- `s3://lab1-dev-incident-reports-183295437238/reports/lab1-incident-20260707T101045Z.md`

## Required Logs Insights Queries Verified

All four required query keys completed successfully:

- `app_error_rate_over_time`
- `app_latest_50_db_error_lines`
- `waf_allow_vs_block`
- `waf_top_blocked_ip_uri_pairs`

The Markdown report also includes a deterministic `Required Query Evidence Summary` appendix generated from the evidence JSON.

## Safety Rules

The Lambda prompt and evidence structure enforce:

- Never include passwords.
- Use only evidence.
- If unknown, say Unknown.
- Cite evidence keys for claims.

Secrets Manager access was tightened from `GetSecretValue` to `DescribeSecret`, so the Lambda collects metadata without reading or exposing secret values.

## Evidence Screenshots

Screenshots are saved under:

- `deliverables/screenshots/1c_bonus_h/01-hcp-apply-success.png`
- `deliverables/screenshots/1c_bonus_h/02-lambda-invoke-success.png`
- `deliverables/screenshots/1c_bonus_h/03-s3-required-objects-head.png`
- `deliverables/screenshots/1c_bonus_h/04-final-evidence-query-statuses.png`
- `deliverables/screenshots/1c_bonus_h/05-required-query-evidence-summary.png`
