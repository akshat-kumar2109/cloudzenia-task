# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets           = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project}-${var.environment}-alb"
    Environment = var.environment
  }
}

# ALB Listener (HTTPS)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

# HTTP to HTTPS redirect
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Target Groups
resource "aws_lb_target_group" "docker" {
  name                 = "${var.project}-${var.environment}-docker-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher            = "200,302,404"
    path               = "/"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 10
    unhealthy_threshold = 5
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }

  tags = {
    Name        = "${var.project}-${var.environment}-docker-tg"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "instance" {
  name                 = "${var.project}-${var.environment}-instance-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher            = "200,302,404"
    path               = "/"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 10
    unhealthy_threshold = 5
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }

  tags = {
    Name        = "${var.project}-${var.environment}-instance-tg"
    Environment = var.environment
  }
}

# Listener Rules for HTTPS
resource "aws_lb_listener_rule" "docker_https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.docker.arn
  }

  condition {
    host_header {
      values = [
        "ec2-docker*.${var.domain_name}",
        "ec2-alb-docker.${var.domain_name}"
      ]
    }
  }
}

resource "aws_lb_listener_rule" "instance_https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instance.arn
  }

  condition {
    host_header {
      values = [
        "ec2-instance*.${var.domain_name}",
        "ec2-alb-instance.${var.domain_name}"
      ]
    }
  }
} 