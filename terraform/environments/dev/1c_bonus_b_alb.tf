# -----------------------------------------------------------------------------
# LAB1 Bonus B - Public ALB to Private EC2
# Purpose:
# - Create an internet-facing Application Load Balancer in public subnets
# - Keep EC2 private in the private app subnet
# - Forward ALB HTTP traffic to the private EC2 app on var.app_port
# -----------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Allow public HTTP access to the LAB1 Bonus B ALB"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-alb-sg"
    }
  )
}

resource "aws_security_group_rule" "alb_http_inbound" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow public HTTP traffic to the ALB"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_all_outbound" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow ALB outbound traffic to targets"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb" "app" {
  name               = "${local.name_prefix}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]

  subnets = [
    aws_subnet.public.id,
    aws_subnet.public_b.id
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-alb"
    }
  )
}

resource "aws_lb_target_group" "app" {
  name        = "${local.name_prefix}-app-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-app-tg"
    }
  )
}

resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.ec2_app.id
  port             = var.app_port
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
