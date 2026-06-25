# -----------------------------------------------------------------------------
# LAB1 Bonus E - AWS WAF Logging
# Purpose:
# - Send AWS WAF Web ACL logs to CloudWatch Logs
# - Use the required aws-waf-logs-* destination naming pattern
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-${local.name_prefix}"
  retention_in_days = 14

  tags = local.common_tags
}

resource "aws_wafv2_web_acl_logging_configuration" "app" {
  resource_arn = aws_wafv2_web_acl.app.arn

  log_destination_configs = [
    aws_cloudwatch_log_group.waf_logs.arn
  ]
}
