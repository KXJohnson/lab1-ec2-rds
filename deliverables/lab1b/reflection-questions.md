# Lab 1b Reflection Questions

## Checkpoint 11.1 — Operations, Secrets, and Incident Response Reflection

### A) Why might Parameter Store still exist alongside Secrets Manager?

Parameter Store and Secrets Manager can exist together because they solve related but different operational problems.

Parameter Store is useful for stable configuration values such as database endpoints, ports, database names, environment settings, and feature flags. These values are important to the application, but they are not always credentials and may not require rotation.

Secrets Manager is better suited for sensitive credential material such as database usernames, passwords, API keys, and other secrets that may need stricter access control, auditing, and rotation support.

In this lab, Parameter Store helped preserve known-good database configuration values, while Secrets Manager stored the runtime database credentials used by the EC2 application. Keeping both systems allowed recovery without guessing or redeploying the EC2 instance.

---

### B) What breaks first during secret rotation?

During secret rotation, the application usually breaks first when the stored secret and the actual service credential no longer match.

For example, if the password in Secrets Manager is changed but the RDS database user password is not changed to the same value, the EC2 application can still read the secret successfully, but database authentication fails. This creates an application-level outage even though IAM access to Secrets Manager is working.

This lab demonstrated that a secret-read success does not always mean the system is healthy. The full dependency chain includes IAM access, secret retrieval, database network connectivity, and successful database authentication.

---

### C) Why should alarms be based on symptoms instead of causes?

Alarms should be based on symptoms because symptoms reflect the user-facing or service-facing impact of a problem.

A database connection failure can have many possible causes, including an incorrect password, a security group issue, an unavailable database, a missing secret, or a network problem. If the alarm is tied to only one assumed cause, it may miss other real failures.

In this lab, the CloudWatch alarm was based on application failure logs. That made the alarm more useful operationally because it detected the symptom that mattered: the application could not complete its database workflow.

---

### D) How does this lab reduce mean time to recovery (MTTR)?

This lab reduces mean time to recovery by making the system observable, recoverable, and less dependent on guesswork.

CloudWatch Logs provided evidence of the application failure. The CloudWatch alarm showed that the failure condition was detected automatically. Parameter Store and Secrets Manager provided known locations for the database configuration and credentials. Because those values were stored centrally, recovery could be performed by restoring the correct secret or configuration instead of rebuilding the EC2 instance or redeploying the entire environment.

The recovery process was faster because the troubleshooting path was clear: inspect logs, identify the failure, verify stored configuration, restore the correct value, and confirm service health with the application endpoint.

---

### E) What would you automate next?

The next automation I would add is a health-check and recovery runbook workflow.

First, I would automate a recurring application health check against the EC2 endpoint. If the endpoint fails, the workflow should check CloudWatch Logs, confirm whether the error is related to secret retrieval or database authentication, and collect the relevant evidence.

Second, I would automate safer secret rotation by ensuring that the RDS password and the Secrets Manager value are updated together in a controlled process. The automation should validate the new credential before completing the rotation.

Third, I would add an incident-response runbook that documents the exact commands for checking Parameter Store, Secrets Manager, CloudWatch Logs, CloudWatch Alarms, and application health. This would make recovery repeatable and reduce the chance of mistakes during an incident.

Together, these improvements would move the project closer to a production-ready operations workflow.
