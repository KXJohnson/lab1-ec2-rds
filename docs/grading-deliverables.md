
---

## 2. `docs/grading-deliverables.md`

```markdown
# LAB1 Grading Deliverables

Use this file as the screenshot and submission checklist for LAB1.

---

## 1a — Networking

Evidence to capture:

- VPC exists
- Public subnet exists for EC2
- Private subnet or DB subnet group exists for RDS
- Route table configuration is visible
- EC2 security group allows required inbound access
- RDS security group allows MySQL only from EC2 security group

Screenshots to submit:

- VPC details
- Subnets
- Route tables
- EC2 security group inbound rules
- RDS security group inbound rules

---

## 1b — EC2 + CloudWatch

Evidence to capture:

- EC2 instance is running
- IAM instance profile is attached
- Application is installed/running
- CloudWatch log group exists
- Log stream is receiving logs
- CloudWatch alarm exists

Screenshots to submit:

- EC2 instance summary
- IAM role attached to EC2
- CloudWatch log group
- CloudWatch log stream
- CloudWatch alarm configuration

---

## 1c — RDS + Secrets

Evidence to capture:

- RDS MySQL instance exists
- RDS is not publicly accessible unless explicitly required by the lab
- DB security group allows port 3306 only from the EC2 security group
- AWS Secrets Manager secret exists
- Application retrieves DB credentials dynamically
- DB password is not exposed in repo, logs, outputs, CLI history, or Terraform state outputs

Screenshots to submit:

- RDS instance summary
- RDS connectivity/security tab
- Secrets Manager secret metadata only, not the secret value
- HCP Terraform successful plan/apply
- Application successfully connecting to the database