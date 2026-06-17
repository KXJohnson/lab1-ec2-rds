# -----------------------------------------------------------------------------
# LAB1 Bonus B - CloudWatch Dashboard
# Purpose:
# - Create a CloudWatch dashboard for the ALB and WAF layer
# - Show ALB request count, target response time, ALB 5XX, target 5XX
# - Show WAF allowed/counted requests
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "bonus_b" {
  dashboard_name = "${local.name_prefix}-bonus-b-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "ALB Request Count"
          region = var.aws_region
          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              aws_lb.app.arn_suffix
            ]
          ]
          stat   = "Sum"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "ALB Target Response Time"
          region = var.aws_region
          metrics = [
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "LoadBalancer",
              aws_lb.app.arn_suffix
            ]
          ]
          stat   = "Average"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "ALB 5XX Errors"
          region = var.aws_region
          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_ELB_5XX_Count",
              "LoadBalancer",
              aws_lb.app.arn_suffix
            ],
            [
              ".",
              "HTTPCode_Target_5XX_Count",
              ".",
              "."
            ]
          ]
          stat   = "Sum"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "WAF Requests"
          region = var.aws_region
          metrics = [
            [
              "AWS/WAFV2",
              "AllowedRequests",
              "WebACL",
              aws_wafv2_web_acl.app.name,
              "Rule",
              "ALL",
              "Region",
              var.aws_region
            ],
            [
              ".",
              "CountedRequests",
              ".",
              ".",
              ".",
              "AWSManagedRulesCommonRuleSet",
              ".",
              "."
            ]
          ]
          stat   = "Sum"
          period = 300
        }
      }
    ]
  })
}
