# Auto-IR Runbook

## Human + Amazon Bedrock Incident Response

## Purpose

This runbook defines how a human on-call engineer safely uses 
the Amazon Bedrock-generated incident report, verifies it 
against raw evidence, manages remediation, and produces a final 
auditable incident artifact.

> **Core rule:** Bedrock accelerates analysis. Humans own 
correctness.

## Scope

This runbook applies to incidents processed by the LAB1 
automated incident reporter.

The automated workflow:

1. Receives a CloudWatch alarm through Amazon SNS.
2. Collects alarm metadata.
3. Runs CloudWatch Logs Insights queries.
4. Collects approved Systems Manager Parameter Store metadata.
5. Collects approved Secrets Manager metadata without exposing 
secret values.
6. Sends the evidence to Amazon Bedrock.
7. Stores evidence JSON and generated Markdown in Amazon S3.
8. Publishes a report-ready SNS notification.

The human on-call engineer remains responsible for validating 
the report, determining severity and impact, approving 
remediation, and completing the final incident record.

## Incident Artifacts

The automated reporter creates two objects:

reports/<incident_id>.json
reports/<incident_id>.md

The JSON object is the structured evidence record.

The Markdown object is the Bedrock-generated working report.

Neither object is considered final until it has been reviewed 
by a human responder.

## Roles and Responsibilities

# Automated Incident Reporter

The automated reporter:
- receives the alarm event;
- gathers configured evidence;
- runs the required Logs Insights queries;
- generates an initial incident analysis;
- stores JSON and Markdown artifacts in Amazon S3;
- and sends a report-ready notification.

The automated reporter must not:
- approve remediation;
- expose passwords or secret values;
- invent missing evidence;
- declare final severity;
- or replace human investigation.

# Human On-Call Engineer

The human on-call engineer:
- acknowledges the incident;
- retrieves the generated artifacts;
- verifies the alarm metadata;
- validates every material claim against raw evidence;
- determines impact and severity;
- approves or performs remediation;
- verifies recovery;
- documents decisions and actions;
- and creates the final human-reviewed incident artifact.

## Incident Response Procedure

### 1. Acknowledge the Incident
a. Review the CloudWatch alarm or SNS notification.
b. Record the incident identifier.
c. Record the alarm name.
d. Record the AWS Region and account.
e. Record the notification time.
f. Confirm that the report-ready notification refers to the same 
incident.
g. Do not begin remediation solely from the Bedrock summary.

### 2. Retrieve the Generated Artifacts

Retrieve both S3 objects:
reports/<incident_id>.json
reports/<incident_id>.md

Confirm that:
- both objects exist;
- both use the same incident identifier;
- their timestamps correspond to the alarm;
- and both describe the same event.

Preserve the original objects. Do not overwrite them.

### 3. Verify Alarm Metadata

Compare the report against the original CloudWatch alarm or SNS 
event.

Verify:
- alarm name;
- alarm state;
- state-change timestamp;
- metric namespace;
- metric name;
- threshold;
- evaluation period;
- comparison operator;
- resource dimensions;
- and reason for the state transition.

If a value is missing, record it as Unknown.

Do not infer missing alarm fields.

### 4. Review Query Execution Status

Review the evidence JSON and confirm the status of every Logs 
Insights query.

The required queries are:
1. Application error rate grouped into one-minute bins.
2. Latest 50 database-related application error lines.
3. WAF allow-versus-block totals.
4. Top blocked WAF client IP and URI pairs.

For each query, confirm:
- the correct log group was used;
- the query completed successfully;
- the query time range covered the incident;
- the result rows are present;
- and the timestamps correspond to the alarm window.

Interpret statuses carefully:
- "Complete" with results means evidence was collected.
- "Complete" with zero rows means no matching entries were found 
in that query window.
- "Failed", "Cancelled", or "Timeout" means the evidence is 
unavailable.
- Missing output must be recorded as "Unknown".

A query with zero results does not prove that no incident 
occurred.

### 5. Validate Bedrock Claims Against Evidence

Review every material claim in the Markdown report.

For each claim:
1. Locate the cited evidence key.
2. Open the matching value in the JSON evidence.
3. Compare the report statement with the raw evidence.
4. Confirm that the statement does not exceed what the evidence 
proves.
5. Mark unsupported statements as unverified.
6. Correct or remove inaccurate conclusions.

Material claims include:
- probable root cause;
- affected service;
- affected resource;
- incident start time;
- application error increase;
- database connectivity failure;
- WAF blocking activity;
- suspicious client addresses;
- customer impact;
-and remediation recommendations.

A Bedrock statement without supporting evidence is a 
hypothesis, not a fact.

### 6. Review Application Log Evidence

Review:
- the application error-rate results;
-database-related error lines; 
- timestamps;
- error messages;
- affected components;
- and recurrence patterns.

Determine whether errors began before, during, or after the 
alarm transition.

Do not assume that the most recent log line is the root cause.

### 7. Review WAF Evidence

Review:
- allowed request totals;
- blocked request totals;
- top blocked client IP addresses;
- requested URIs;
- timestamps;
- and repeated patterns.

A blocked request does not automatically indicate a confirmed 
attack.

Escalate suspicious activity to the security-response process 
when the evidence indicates:
- repeated hostile behavior;
- unusual request volume;
- targeting of sensitive paths;
- or a possible compromise.

### 8. Review SSM Metadata Safely

Verify operational metadata such as:
- parameter names;
- parameter paths;
- ARNs;
- update timestamps;
- and retrieval status.

Do not copy decrypted SecureString values into the incident 
report.

Do not place credentials, passwords, tokens, or connection 
strings in screenshots or evidence artifacts.

### 9. Review Secrets Manager Metadata Safely

Verify only approved metadata such as:
- secret identifier;
- ARN;
- version metadata;
- last-changed timestamp;
- and retrieval status.

Never include:
- database passwords;
- secret values;
- API keys;
- tokens;
- private keys;
- or decrypted credentials.

If secret access is needed for remediation, use the approved 
operational procedure and do not place the value in the incident 
record.

### 10. Handle Missing Evidence

When evidence is missing:
1. Record the value as Unknown.
2. Identify the missing evidence source.
3. Record why it is unavailable.
4. Determine whether additional evidence collection is needed.
5. Avoid substituting assumptions for missing data.

Examples include:
- a failed Logs Insights query;
- an unavailable log group;
- missing alarm dimensions;
- unavailable metadata;
- or an incomplete report artifact.

### 11. Handle Conflicting Evidence

When sources conflict:
1. Preserve both observations.
2. Record the timestamp and source of each observation.
3. Determine whether the difference is caused by collection 
timing.
4. Review the original CloudWatch logs and alarm history.
5. Collect additional evidence when required.
6. Record the human conclusion separately.

Do not ask Bedrock to resolve conflicting evidence without 
reviewing the underlying sources.

### 12. Determine Severity and Impact

The human on-call engineer determines the final severity.

Consider:

- customer impact;
- service availability;
- duration;
- data integrity;
- security exposure;
- blast radius;
- recurrence;
- and whether the incident remains active.

Record:
- final severity;
- affected services;
- confirmed impact;
- possible impact;
- incident start time;
- detection time;
- mitigation time;
- and recovery time.

Clearly distinguish confirmed facts from estimates.

### 13. Approve Remediation

Before taking action:

1. Confirm that the proposed remediation is supported by 
evidence.
2. Assess possible side effects.
3. Preserve evidence that might be overwritten.
4. Follow change-management requirements.
5. Escalate when approval is required.
6. Record the chosen action and reason.

Possible remediation actions include:
- restarting the application service;
- reverting a faulty deployment;
- correcting an application configuration;
- correcting database connectivity;
- increasing capacity;
- blocking a confirmed malicious source;
- or escalating to the application, database, networking, or 
security owner.

Bedrock recommendations are advisory.

They must not be executed automatically unless a separate 
approved automation policy explicitly authorizes them.

### 14. Verify Recovery

After remediation:
1. Confirm the application health endpoint succeeds.
2. Confirm expected application functionality succeeds.
3. Confirm database connectivity when applicable.
4. Rerun relevant Logs Insights queries.
5. Confirm new errors are no longer increasing.
6. Review the CloudWatch alarm state.
7. Confirm the alarm returns to OK when appropriate.
8. Record verification timestamps and results.

Do not close the incident solely because the alarm returned to 
OK.

### 15. Create the Final Human-Reviewed Artifact

Create a separate final record such as:

reports/<incident_id>-human-reviewed.md

The final artifact must include:
- incident identifier;
- reviewer name or role;
- review timestamp;
- alarm metadata;
- incident timeline;
- affected resources;
- confirmed impact;
- confirmed evidence;
- evidence references;
- root cause or Unknown;
- remediation actions;
- recovery validation;
- remaining risks;
- follow-up actions;
- and final severity.

The record must clearly distinguish:
- raw evidence;
- Bedrock-generated analysis;
- human conclusions;
- and approved actions.

Do not overwrite the original JSON or generated Markdown 
report.

### 16. Conduct Post-Incident Review

For significant incidents:
1. Review whether the alarm fired at the correct time.
2. Review whether the query window was sufficient.
3. Identify missing evidence.
4. Evaluate the accuracy of the Bedrock report.
5. Document unsupported or misleading statements.
6. Improve evidence collection where needed.
7. Improve prompts only when supported by observed deficiencies.
8. Create corrective actions.
9. Assign owners.
10. Assign target completion dates.

Do not increase the confidence of generated output merely to 
make the report appear more complete.

Safety Rules
- Bedrock output is advisory.
- Humans own correctness.
- Never expose passwords or secret values.
- Never invent missing evidence.
- Use Unknown when evidence does not establish a fact.
- Validate claims against raw evidence.
- Preserve original artifacts.
- Record human changes and decisions.
- Do not bypass change-management controls.
- Escalate suspected security incidents.
- Do not automatically execute generated remediation 
recommendations.

## Completion Criteria

The incident is complete when:
- the notification has been acknowledged;
- both generated artifacts have been retrieved;
- alarm metadata has been verified;
- query statuses and raw results have been reviewed;
- all material Bedrock claims have been validated;
- impact and severity have been human-approved;
- remediation has been recorded;
- recovery has been verified;
- the final auditable artifact has been preserved;
- and required follow-up actions have been assigned.
