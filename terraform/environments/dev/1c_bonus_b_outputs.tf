# -----------------------------------------------------------------------------
# LAB1 Bonus B Outputs
# -----------------------------------------------------------------------------

output "bonus_b_alb_dns_name" {
  description = "DNS name for the LAB1 Bonus B public Application Load Balancer."
  value       = aws_lb.app.dns_name
}

output "bonus_b_alb_arn" {
  description = "ARN of the LAB1 Bonus B Application Load Balancer."
  value       = aws_lb.app.arn
}

output "bonus_b_target_group_arn" {
  description = "ARN of the LAB1 Bonus B ALB target group."
  value       = aws_lb_target_group.app.arn
}
