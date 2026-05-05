
---

## 4. `deliverables/validation-commands.md`

```markdown
# LAB1 Validation Commands

Replace values in angle brackets before running.

---

## Confirm AWS Identity

```bash
aws sts get-caller-identity

#Confirm EC2 Instance
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=<EC2_NAME>" \
  --query "Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,PrivateIpAddress,IamInstanceProfile.Arn]" \
  --output table

#Confirm Security Group Rules
  aws ec2 describe-security-groups \
  --group-ids <SECURITY_GROUP_ID> \
  --query "SecurityGroups[*].IpPermissions" \
  --output json

#Confirming RDS Instance
aws rds describe-db-instances \
  --db-instance-identifier <RDS_IDENTIFIER> \
  --query "DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,PubliclyAccessible,Endpoint.Address,DBSubnetGroup.DBSubnetGroupName]" \
  --output table

#Confirm Secret Exists Without Revealing Value
  aws secretsmanager describe-secret \
  --secret-id <SECRET_ID_OR_NAME>

#Confirm CloudWatch Log Groups
  aws logs describe-log-groups \
  --log-group-name-prefix /aws/ec2/


  #Confirm CloudWatch Alarm
  aws cloudwatch describe-alarms \
  --alarm-names <ALARM_NAME>
