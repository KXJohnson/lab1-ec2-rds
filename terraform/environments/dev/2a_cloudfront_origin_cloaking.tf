# -----------------------------------------------------------------------------
# LAB2A - CloudFront Origin Cloaking
#
# Purpose:
# - Make CloudFront the only intended public ingress path to the application
# - Restrict ALB HTTPS ingress to AWS CloudFront origin-facing infrastructure
# - Add application-layer origin authentication with a secret request header
#
# Architecture:
# Internet -> CloudFront -> ALB -> Private EC2 -> RDS
# -----------------------------------------------------------------------------

data "aws_ec2_managed_prefix_list" "cloudfront_origin" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group_rule" "alb_https_from_cloudfront" {
  security_group_id = aws_security_group.alb.id

  description = "Allow HTTPS to ALB from CloudFront origin-facing infrastructure"
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"

  prefix_list_ids = [
    data.aws_ec2_managed_prefix_list.cloudfront_origin.id
  ]
}


# -----------------------------------------------------------------------------
# Origin authentication
#
# CloudFront will inject this randomly generated value into a custom HTTP
# header when contacting the ALB. The ALB forwards a request only when the
# expected header/value pair is present.
# -----------------------------------------------------------------------------

resource "random_password" "cloudfront_origin_header" {
  length  = 32
  special = false
}

resource "aws_lb_listener_rule" "allow_cloudfront_origin" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    http_header {
      http_header_name = "X-Lab2-Origin-Verify"
      values           = [random_password.cloudfront_origin_header.result]
    }
  }
}
