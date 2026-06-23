# -----------------------------------------------------------------------------
# LAB1 Bonus C - Route53 + ACM + HTTPS for ALB
# -----------------------------------------------------------------------------

locals {
  bonus_c_app_fqdn = "${var.app_subdomain}.${var.domain_name}"
}

data "aws_route53_zone" "bonus_c" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_acm_certificate" "app" {
  domain_name       = local.bonus_c_app_fqdn
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

resource "aws_security_group_rule" "alb_https_inbound" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow public HTTPS traffic to the ALB"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.app.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_route53_record" "app_alias" {
  zone_id = data.aws_route53_zone.bonus_c.zone_id
  name    = local.bonus_c_app_fqdn
  type    = "A"

  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}
