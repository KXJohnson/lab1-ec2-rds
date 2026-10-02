# -----------------------------------------------------------------------------
# LAB1 Bonus C - Route53 + ACM + HTTPS for ALB
# -----------------------------------------------------------------------------

locals {
  bonus_c_app_fqdn = "${var.app_subdomain}.${var.domain_name}"
  lab2_origin_fqdn = "origin.${var.domain_name}"
}

data "aws_route53_zone" "bonus_c" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_acm_certificate" "app" {
  domain_name = local.bonus_c_app_fqdn
  subject_alternative_names = [
    var.domain_name,
    local.lab2_origin_fqdn
  ]
  validation_method = "DNS"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-app-acm"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "app_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.app.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.bonus_c.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "app" {
  certificate_arn         = aws_acm_certificate.app.arn
  validation_record_fqdns = [for record in aws_route53_record.app_cert_validation : record.fqdn]
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.app.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }
}

resource "aws_route53_record" "app_alias" {
  zone_id = data.aws_route53_zone.bonus_c.zone_id
  name    = local.bonus_c_app_fqdn
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.app.domain_name
    zone_id                = aws_cloudfront_distribution.app.hosted_zone_id
    evaluate_target_health = false
  }
}

# -----------------------------------------------------------------------------
# LAB2 - Dedicated CloudFront origin hostname
#
# CloudFront uses this hostname when connecting to the ALB over HTTPS.
# Keeping the origin hostname separate from the public application aliases
# prevents a DNS loop after the apex and app records are moved to CloudFront.
# -----------------------------------------------------------------------------

resource "aws_route53_record" "origin_alias" {
  zone_id = data.aws_route53_zone.bonus_c.zone_id
  name    = local.lab2_origin_fqdn
  type    = "A"

  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}
