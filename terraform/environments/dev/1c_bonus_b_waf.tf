# -----------------------------------------------------------------------------
# LAB1 Bonus B - AWS WAF for ALB
# Purpose:
# - Create a regional AWS WAFv2 Web ACL
# - Attach the Web ACL to the public Application Load Balancer
# - Enable CloudWatch metrics and sampled requests
# - Start AWS managed common rules in COUNT mode to avoid blocking lab traffic
# -----------------------------------------------------------------------------

resource "aws_wafv2_web_acl" "app" {
  name        = "${local.name_prefix}-waf"
  description = "LAB1 Bonus B WAF for the application load balancer"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-waf-common-rules"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-waf"
    sampled_requests_enabled   = true
  }

  tags = local.common_tags
}

resource "aws_wafv2_web_acl_association" "app_alb" {
  resource_arn = aws_lb.app.arn
  web_acl_arn  = aws_wafv2_web_acl.app.arn
}
