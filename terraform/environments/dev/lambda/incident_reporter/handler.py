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
BEDROCK_MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "anthropic.claude-3-haiku-20240307-v1:0")


def lambda_handler(event, context):
    """
    LAB1 Bonus G IncidentReporter Lambda.

    Expected flow:
    SNS alarm event -> collect CloudWatch Logs Insights evidence ->
    collect SSM/Secrets Manager recovery context -> call Bedrock ->
    write incident report to S3 -> publish report-ready SNS message.
    """

    print("Received event:")
    print(json.dumps(event, default=str))

    incident_id = build_incident_id()
    alarm_message = extract_alarm_message(event)

    app_evidence = collect_app_log_evidence()
    waf_evidence = collect_waf_log_evidence()
    recovery_context = collect_recovery_context()

    prompt = build_bedrock_prompt(
        incident_id=incident_id,
        alarm_message=alarm_message,
        app_evidence=app_evidence,
        waf_evidence=waf_evidence,
        recovery_context=recovery_context,
    )

    report_markdown = invoke_bedrock(prompt)

    report_key = write_report_to_s3(
        incident_id=incident_id,
        report_markdown=report_markdown,
    )

    publish_report_ready_message(
        incident_id=incident_id,
        report_key=report_key,
    )

    return {
        "statusCode": 200,
        "incident_id": incident_id,
        "report_bucket": REPORT_BUCKET,
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
        "recent_app_logs": "fields @timestamp, @message | sort @timestamp desc | limit 20",
        "recent_error_lines": "fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 10",
    }

    return run_query_pack(APP_LOG_GROUP, queries)


def collect_waf_log_evidence():
    queries = {
        "recent_waf_logs": "fields @timestamp, @message | sort @timestamp desc | limit 20",
        "waf_actions": "fields action | stats count() as requests by action | sort requests desc",
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

        response = logs.start_query(
            logGroupName=log_group_name,
            startTime=start_time,
            endTime=end_time,
            queryString=query_string.strip(),
        )

        query_id = response["queryId"]
        results[name] = wait_for_query(query_id)

    return results


def wait_for_query(query_id):
    for _ in range(30):
        response = logs.get_query_results(queryId=query_id)

        if response["status"] in ["Complete", "Failed", "Cancelled", "Timeout"]:
            return {
                "status": response["status"],
                "results": response.get("results", []),
            }

        time.sleep(1)

    return {
        "status": "TimedOutWaiting",
        "results": [],
    }


def collect_recovery_context():
    context = {
        "ssm_parameters": {},
        "secret_metadata": {},
    }

    for name in ["/lab/db/endpoint", "/lab/db/port", "/lab/db/name"]:
        try:
            response = ssm.get_parameter(Name=name, WithDecryption=True)
            context["ssm_parameters"][name] = response["Parameter"]["Value"]
        except Exception as exc:
            context["ssm_parameters"][name] = f"ERROR: {exc}"

    try:
        secret = secretsmanager.get_secret_value(SecretId=SECRET_ID)
        secret_payload = json.loads(secret.get("SecretString", "{}"))

        # Do not expose the password in the incident report.
        secret_payload.pop("password", None)

        context["secret_metadata"] = secret_payload
    except Exception as exc:
        context["secret_metadata"] = {"error": str(exc)}

    return context


def build_bedrock_prompt(
    incident_id,
    alarm_message,
    app_evidence,
    waf_evidence,
    recovery_context,
):
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

Use the evidence below. Do not invent facts. If evidence is incomplete, say so.

Alarm message:
{json.dumps(alarm_message, indent=2, default=str)}

Application log evidence:
{json.dumps(app_evidence, indent=2, default=str)}

WAF log evidence:
{json.dumps(waf_evidence, indent=2, default=str)}

Recovery context:
{json.dumps(recovery_context, indent=2, default=str)}
"""


def invoke_bedrock(prompt):
    body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 2000,
        "temperature": 0.2,
        "messages": [
            {
                "role": "user",
                "content": prompt,
            }
        ],
    }

    response = bedrock.invoke_model(
        modelId=BEDROCK_MODEL_ID,
        body=json.dumps(body),
    )

    response_body = json.loads(response["body"].read())
    return response_body["content"][0]["text"]


def write_report_to_s3(incident_id, report_markdown):
    key = f"incident-reports/{incident_id}.md"

    s3.put_object(
        Bucket=REPORT_BUCKET,
        Key=key,
        Body=report_markdown.encode("utf-8"),
        ContentType="text/markdown",
    )

    return key


def publish_report_ready_message(incident_id, report_key):
    message = {
        "incident_id": incident_id,
        "report_bucket": REPORT_BUCKET,
        "report_key": report_key,
        "s3_uri": f"s3://{REPORT_BUCKET}/{report_key}",
    }

    sns.publish(
        TopicArn=REPORT_TOPIC_ARN,
        Subject=f"LAB1 Bonus G Incident Report Ready: {incident_id}",
        Message=json.dumps(message, indent=2),
    )
