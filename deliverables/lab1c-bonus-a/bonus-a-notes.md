# LAB1 1C Bonus A — Private EC2 with SSM and VPC Endpoints

## Goal

Bonus A hardens the LAB1 environment by moving the EC2 application server into a private, no-public-IP pattern.

The EC2 instance is no longer publicly reachable. There is no public IP, no public DNS, and no SSH ingress rule. Administration is performed through AWS 
Systems Manager Session Manager.

## Final EC2 State

- Instance ID: i-088c34f25fbe000ec
- Private hostname: ip-10-0-2-230.ec2.internal
- Public IP: none
- Public DNS: none
- SSH ingress rule: removed
- Access method: SSM Session Manager only
- Application service: lab1-app.service

## Terraform Apply Result

HCP Terraform apply completed successfully after the private EC2 move.

Result:

- 1 added
- 0 changed
- 2 destroyed

The apply replaced the EC2 instance and deleted the SSH ingress rule.

## Terraform Output Verification

Terraform outputs confirmed that the instance no longer has public network exposure:

- ec2_app_url = "http://"
- ec2_instance_id = "i-088c34f25fbe000ec"
- ec2_public_dns = ""
- ec2_public_ip = ""

## SSM Verification

SSM describe-instance-information showed the private EC2 instance online:

- InstanceId: i-088c34f25fbe000ec
- Status: Online
- Platform: Amazon Linux

An SSM Session Manager connection was successfully opened to the private instance.

## Application Verification

Inside the SSM session, the application service was checked with:

    systemctl status lab1-app.service --no-pager

The service showed active/running.

The local application endpoint was tested from inside the private EC2 instance with:

    curl -i http://127.0.0.1:80/

The response returned HTTP 200 OK and confirmed:

- secret_read: ok
- database_connection: ok
- database: notes
- table: notes

## VPC Endpoint Verification

The following endpoints were verified as available:

- lab1-dev-s3-gateway-endpoint
- lab1-dev-logs-endpoint
- lab1-dev-ec2messages-endpoint
- lab1-dev-ssm-endpoint
- lab1-dev-kms-endpoint
- lab1-dev-ssmmessages-endpoint
- lab1-dev-secretsmanager-endpoint

## Recommended Screenshots

Save screenshots in:

    deliverables/screenshots/1c_bonus_a/

Recommended screenshots:

1. HCP apply showing EC2 replaced and SSH ingress rule deleted
2. Terraform output showing empty public IP and public DNS
3. SSM describe-instance-information showing private EC2 online
4. SSM session showing lab1-app.service active and curl 127.0.0.1 returning JSON ok
5. VPC endpoints table showing endpoints available

## Security Improvement Summary

After Bonus A:

- EC2 has no public IP.
- EC2 has no public DNS.
- SSH ingress was removed.
- No SSH key access is required.
- Administration uses SSM Session Manager.
- AWS service access is supported through VPC endpoints.
- The application still reads Secrets Manager and connects privately to RDS.
