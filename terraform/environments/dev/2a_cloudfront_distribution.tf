# -----------------------------------------------------------------------------
# LAB2A - CloudFront Distribution
#
# Purpose:
# - Make CloudFront the public application ingress layer
# - Send origin traffic to the ALB over HTTPS
# - Authenticate CloudFront to the ALB with a secret custom header
# - Attach the LAB2 CloudFront-scoped WAF
#
# Viewer:
# Internet -> CloudFront
#
# Origin:
# CloudFront -> origin.kulturalintercessor.org -> ALB
# -----------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "app" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${local.name_prefix}-cloudfront"

  origin {
    origin_id   = "${local.name_prefix}-alb-origin"
    domain_name = local.lab2_origin_fqdn

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Lab2-Origin-Verify"
      value = random_password.cloudfront_origin_header.result
    }
  }

  default_cache_behavior {
    target_origin_id       = "${local.name_prefix}-alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS",
      "PUT",
      "POST",
      "PATCH",
      "DELETE"
    ]

    cached_methods = [
      "GET",
      "HEAD"
    ]

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }
  }

  web_acl_id = aws_wafv2_web_acl.cloudfront.arn

  aliases = [
    var.domain_name,
    local.bonus_c_app_fqdn
  ]

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.app.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-cloudfront"
    }
  )
}
