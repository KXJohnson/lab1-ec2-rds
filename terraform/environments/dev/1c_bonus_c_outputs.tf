# -----------------------------------------------------------------------------
# LAB1 Bonus C Outputs
# -----------------------------------------------------------------------------

output "bonus_c_domain_name" {
  description = "Root domain used for LAB1 Bonus C."
  value       = var.domain_name
}

output "bonus_c_app_fqdn" {
  description = "Fully qualified domain name for the HTTPS LAB1 app."
  value       = local.bonus_c_app_fqdn
}

output "bonus_c_https_url" {
  description = "HTTPS URL for the LAB1 app through Route53, ACM, WAF, and ALB."
  value       = "https://${local.bonus_c_app_fqdn}"
}

output "bonus_c_acm_certificate_arn" {
  description = "ACM certificate ARN for the LAB1 HTTPS ALB listener."
  value       = aws_acm_certificate.app.arn
}

output "bonus_c_route53_zone_id" {
  description = "Route53 hosted zone ID used for LAB1 Bonus C."
  value       = data.aws_route53_zone.bonus_c.zone_id
}
