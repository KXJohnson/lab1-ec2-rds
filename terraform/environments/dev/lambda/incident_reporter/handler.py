import json
import os
import time
from datetime import datetime, timezone

import boto3


logs = boto3.client("logs")
ssm = boto3.client("ssm")
secretsmanager = boto3.client("secretsmanager")
s3 = boto3.client("s3")
sns = boto3.client("sns")
bedrock = boto3.client("bedrock-runtime")


APP_LOG_GROUP = os.environ["APP_LOG_GROUP"]
WAF_LOG_GROUP = os.environ["WAF_LOG_GROUP"]
REPORT_BUCKET = os.environ["REPORT_BUCKET"]
REPORT_TOPIC_ARN = os.environ["REPORT_TOPIC_ARN"]
SECRET_ID = os.environ["SECRET_ID"]
SSM_PARAM_PATH = os.environ.get("SSM_PARAM_PATH", "/lab/db/")
BEDROCK_MODEL_ID = os.environ.get(
    "BEDROCK_MODEL_ID",
    "anthropic.claude-3-haiku-20240307-v1:0",
)


def lambda_handler(event, context):
    """
    LAB1 Bonus H IncidentReporter Lambda.

    SNS alarm event -> collect alarm metadata, CloudWatch Logs Insights evidence,
    SSM Parameter Store values, and Secrets Manager metadata -> call Bedrock ->
    write evidence JSON and report Markdown to S3 -> publish report-ready SNS message.
    """

    print("Received event:")
    print(json.dumps(event, default=str))

    incident_id = build_incident_id()
    alarm_message = extract_alarm_message(event)

    evidence = {
        "incident_id": incident_id,
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "alarm_metadata": alarm_message,
        "logs_insights": {
            "app": collect_app_log_evidence(),
            "waf": collect_waf_log_evidence(),
        },
        "configuration_sources": collect_recovery_context(),
        "safety_rules": [
            "Never include passwords.",
            "Use only evidence.",
            "If unknown, say Unknown.",
            "Cite evidence keys for claims.",
        ],
    }

    prompt = build_bedrock_prompt(
        incident_id=incident_id,
        evidence=evidence,
    )

    report_markdown = invoke_bedrock(prompt)

    evidence_key, report_key = write_incident_objects_to_s3(
        incident_id=incident_id,
        evidence=evidence,
        report_markdown=report_markdown,
    )

    publish_report_ready_message(
        incident_id=incident_id,
        evidence_key=evidence_key,
        report_key=report_key,
    )

    return {
        "statusCode": 200,
        "incident_id": incident_id,
        "report_bucket": REPORT_BUCKET,
        "evidence_key": evidence_key,
        "report_key": report_key,
    }


def build_incident_id():
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    return f"lab1-incident-{timestamp}"


def extract_alarm_message(event):
    """
    SNS wraps the CloudWatch alarm payload as a string in Records[0].Sns.Message.
    """
    try:
        message = event["Records"][0]["Sns"]["Message"]
        return json.loads(message)
    except Exception as exc:
        print(f"Could not parse SNS alarm message as JSON: {exc}")
        return {"raw_event": event}


def collect_app_log_evidence():
    queries = {
        "app_error_rate_over_time": (
            "fields @timestamp, @message "
            "| filter @message like /ERROR|Error|error|FAIL|Fail|fail|Exception|exception/ "
            "| stats count(*) as error_count by bin(1m)"
        ),
        "app_latest_50_db_error_lines": (
            "fields @timestamp, @message "
            "| filter @message like /DB|db|database|Database|mysql|MySQL|RDS|rds|SQL|sql|secret|Secret|connection|Connection/ "
            "| filter @message like /ERROR|Error|error|FAIL|Fail|fail|Exception|exception|denied|Denied|timeout|Timeout/ "
            "| sort @timestamp desc "
            "| limit 50"
        ),
    }

    return run_query_pack(APP_LOG_GROUP, queries)


def collect_waf_log_evidence():
    queries = {
        "waf_allow_vs_block": (
            "fields action "
            "| stats count() as request_count by action "
            "| sort request_count desc"
        ),
        "waf_top_blocked_ip_uri_pairs": (
            "fields httpRequest.clientIp as client_ip, httpRequest.uri as uri, action "
            "| filter action = \"BLOCK\" "
            "| stats count() as blocked_requests by client_ip, uri "
            "| sort blocked_requests desc "
            "| limit 20"
        ),
    }

    return run_query_pack(WAF_LOG_GROUP, queries)


def run_query_pack(log_group_name, queries):
    end_time = int(time.time())
    start_time = end_time - 3600

    results = {}

    for name, query_string in queries.items():
        if not query_string or not query_string.strip():
            results[name] = {
                "status": "SKIPPED",
                "reason": "Empty query string",
            }
            continue

        print(f"Running Logs Insights query: {name} against {log_group_name}")
        print(f"Query string length: {len(query_string.strip())}")
        print(f"Query string repr: {repr(query_string.strip())}")

        try:
            response = logs.start_query(
                logGroupName=log_group_name,
                startTime=start_time,
                endTime=end_time,
                queryString=query_string.strip(),
            )
            query_id = response["queryId"]
            results[name] = wait_for_query(query_id)
            results[name]["query_string"] = query_string.strip()
            results[name]["log_group"] = log_group_name
        except Exception as exc:
            results[name] = {
                "status": "ERROR",
                "error": str(exc),
                "query_string": query_string.strip(),
                "log_group": log_group_name,
            }

    return results


def wait_for_query(query_id):
    for _ in range(30):
        response = logs.get_query_results(queryId=query_id)

        if response["status"] in ["Complete", "Failed", "Cancelled", "Timeout"]:
            return {
                "status": response["status"],
                "results": response.get("results", []),
                "statistics": response.get("statistics", {}),
            }

        time.sleep(1)

    return {
        "status": "TimedOutWaiting",
        "results": [],
        "statistics": {},
    }


def collect_recovery_context():
    context = {
        "ssm_parameters": {},
        "secret_metadata": {},
    }

    for name in [
        f"{SSM_PARAM_PATH}endpoint",
        f"{SSM_PARAM_PATH}port",
        f"{SSM_PARAM_PATH}name",
    ]:
        try:
            response = ssm.get_parameter(Name=name, WithDecryption=False)
            parameter = response["Parameter"]
            context["ssm_parameters"][name] = {
                "name": parameter.get("Name", "Unknown"),
                "type": parameter.get("Type", "Unknown"),
                "value": parameter.get("Value", "Unknown"),
                "version": parameter.get("Version", "Unknown"),
                "last_modified_date": str(parameter.get("LastModifiedDate", "Unknown")),
            }
        except Exception as exc:
            context["ssm_parameters"][name] = {"error": str(exc)}

    try:
        secret = secretsmanager.describe_secret(SecretId=SECRET_ID)
        context["secret_metadata"] = {
            "name": secret.get("Name", "Unknown"),
            "arn": secret.get("ARN", "Unknown"),
            "description": secret.get("Description", "Unknown"),
            "created_date": str(secret.get("CreatedDate", "Unknown")),
            "last_changed_date": str(secret.get("LastChangedDate", "Unknown")),
            "last_accessed_date": str(secret.get("LastAccessedDate", "Unknown")),
            "version_ids_to_stages": secret.get("VersionIdsToStages", {}),
            "tags": secret.get("Tags", []),
        }
    except Exception as exc:
        context["secret_metadata"] = {"error": str(exc)}

    return context


def build_bedrock_prompt(incident_id, evidence):
    return f"""
You are an AWS incident response assistant.

Create a concise Markdown incident report using this exact structure:

# Incident Report: {incident_id} — LAB1 Application Incident

## 1. Executive Summary
## 2. Timeline (UTC)
## 3. Scope and Blast Radius
## 4. Evidence Collected
### 4.1 CloudWatch Alarm
### 4.2 App Logs (CloudWatch Logs Insights)
### 4.3 WAF Logs (CloudWatch Logs Insights)
### 4.4 Configuration Sources (for Recovery)
## 5. Root Cause Analysis
## 6. Resolution
## 7. Preventive Actions
## 8. Appendix

Rules:
- Use only the evidence below.
- Never include passwords or secret values.
- If a fact is unknown or not shown in evidence, write "Unknown".
- Cite evidence keys for claims, for example: evidence.alarm_metadata, evidence.logs_insights.app.app_error_rate_over_time, evidence.logs_insights.waf.waf_allow_vs_block, evidence.configuration_sources.ssm_parameters, or evidence.configuration_sources.secret_metadata.
- Do not invent causes, timelines, impacts, or remediation steps.

Evidence:
{json.dumps(evidence, indent=2, default=str)}
"""


def invoke_bedrock(prompt):
    response = bedrock.converse(
        modelId=BEDROCK_MODEL_ID,
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "text": prompt,
                    }
                ],
            }
        ],
        inferenceConfig={
            "maxTokens": 2000,
            "temperature": 0.2,
        },
    )

    return response["output"]["message"]["content"][0]["text"]


def write_incident_objects_to_s3(incident_id, evidence, report_markdown):
    evidence_key = f"reports/{incident_id}.json"
    report_key = f"reports/{incident_id}.md"

    s3.put_object(
        Bucket=REPORT_BUCKET,
        Key=evidence_key,
        Body=json.dumps(evidence, indent=2, default=str).encode("utf-8"),
        ContentType="application/json",
    )

    s3.put_object(
        Bucket=REPORT_BUCKET,
        Key=report_key,
        Body=report_markdown.encode("utf-8"),
        ContentType="text/markdown",
    )

    return evidence_key, report_key


def publish_report_ready_message(incident_id, evidence_key, report_key):
    message = {
        "incident_id": incident_id,
        "report_bucket": REPORT_BUCKET,
        "evidence_key": evidence_key,
        "report_key": report_key,
        "evidence_s3_uri": f"s3://{REPORT_BUCKET}/{evidence_key}",
        "report_s3_uri": f"s3://{REPORT_BUCKET}/{report_key}",
    }

    sns.publish(
        TopicArn=REPORT_TOPIC_ARN,
        Subject=f"LAB1 Bonus H Incident Report Ready: {incident_id}",
        Message=json.dumps(message, indent=2),
    )
