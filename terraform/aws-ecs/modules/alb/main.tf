# ---------------------------------------------
# Application Load Balancer
# ---------------------------------------------
resource "aws_lb" "main" {
  name               = "alb-${var.project}-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  tags = { Name = "alb-${var.project}-${var.environment}" }
}

resource "aws_lb_target_group" "main" {
  name        = "tg-${var.project}-${var.environment}"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health" # <-- CHANGE THIS: your health endpoint
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  # For production, add HTTPS listener instead:
  # port     = 443
  # protocol = "HTTPS"
  # certificate_arn = var.acm_certificate_arn
}
