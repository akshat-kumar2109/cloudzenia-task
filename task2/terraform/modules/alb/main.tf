# ALB remains unchanged
resource "aws_lb" "main" {
  name               = "${var.project}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project}-${var.environment}-alb"
    Environment = var.environment
  }
}

# HTTPS Listener
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

# HTTP → HTTPS Redirect
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

# Target Group for ec2-nginx-production-instance-1
resource "aws_lb_target_group" "instance1" {
  name     = "${var.project}-${var.environment}-instance1-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200,302,404"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    unhealthy_threshold = 5
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = false
  }

  tags = {
    Name        = "${var.project}-${var.environment}-instance1-tg"
    Environment = var.environment
  }
}

# Target Group for ec2-nginx-production-instance-2
resource "aws_lb_target_group" "instance2" {
  name     = "${var.project}-${var.environment}-instance2-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200,302,404"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    unhealthy_threshold = 5
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = false
  }

  tags = {
    Name        = "${var.project}-${var.environment}-instance2-tg"
    Environment = var.environment
  }
}

# Register instances to target groups
resource "aws_lb_target_group_attachment" "instance1_attachment" {
  target_group_arn = aws_lb_target_group.instance1.arn
  target_id        = var.ec2_instance1_id
  port             = 80
}

resource "aws_lb_target_group_attachment" "instance2_attachment" {
  target_group_arn = aws_lb_target_group.instance2.arn
  target_id        = var.ec2_instance2_id
  port             = 80
}

# HTTPS Routing Rules

resource "aws_lb_listener_rule" "instance1_https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instance1.arn
  }

  condition {
    host_header {
      values = [
        "ec2-instance1.${var.domain_name}",
        "ec2-docker1.${var.domain_name}"
      ]
    }
  }
}

resource "aws_lb_listener_rule" "instance2_https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instance2.arn
  }

  condition {
    host_header {
      values = [
        "ec2-instance2.${var.domain_name}",
        "ec2-docker2.${var.domain_name}"
      ]
    }
  }
}

resource "aws_lb_listener_rule" "nginx" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instance1.arn
  }

  condition {
    host_header {
      values = ["ec2-alb-instance.${var.domain_name}"]
    }
  }
}

# HTTPS Listener Rule - Docker (ec2-alb-docker subdomain)
resource "aws_lb_listener_rule" "docker" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instance1.arn
  }

  condition {
    host_header {
      values = ["ec2-alb-docker.${var.domain_name}"]
    }
  }
}
