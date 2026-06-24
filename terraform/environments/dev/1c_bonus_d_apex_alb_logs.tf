# -----------------------------------------------------------------------------
# LAB1 Bonus D - Apex Route53 ALIAS + ALB Access Logs
# Purpose:
# - Point the zone apex domain to the existing public ALB
# - Store ALB access logs in S3 for audit and troubleshooting
# -----------------------------------------------------------------------------

locals {
  bonus_d_alb_logs_bucket_name = "${local.name_prefix}-alb-logs-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket" "alb_logs" {
  bucket        = local.bonus_d_alb_logs_bucket_name
  force_destroy = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-alb-logs"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version  = "2012-10-17"
    Action   = "s3:PutObject"
    Resource = "${aws_s3_bucket.alb_logs.arn}/${var.alb_access_logs_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"

    Condition = {
      StringEquals = {
        "s3:x-amz-acl" = "bucket-owner-full-control"
      }
    }
    Statement = [
      {
        Sid    = "AllowALBAccessLogDelivery"
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/${var.alb_access_logs_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })
}

resource "aws_route53_record" "apex_alias" {
  zone_id = data.aws_route53_zone.bonus_c.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}
