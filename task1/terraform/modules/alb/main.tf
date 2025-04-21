locals {
  name = "${var.project}-${var.environment}"
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project}-alb"
    Environment = var.environment
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg"
  description = "ALB Security Group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-alb-sg"
    Environment = var.environment
  }
}

# Null resource to disable ALB deletion protection before destroy
resource "null_resource" "disable_alb_deletion_protection" {
  triggers = {
    alb_arn = aws_lb.main.arn
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
#!/bin/bash
set -e

echo "Disabling deletion protection for ALB: ${self.triggers.alb_arn}"
aws elbv2 modify-load-balancer-attributes \
    --load-balancer-arn ${self.triggers.alb_arn} \
    --attributes Key=deletion_protection.enabled,Value=false

echo "Waiting for ALB attribute update..."
sleep 30
EOF
  }

  depends_on = [aws_lb.main]
}

# Target Group for WordPress
resource "aws_lb_target_group" "wordpress" {
  name        = "${var.project}-wp-tg"
  port        = var.wordpress_target_group_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 35
    matcher            = "200,301,302"
    path               = "/"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 30
    unhealthy_threshold = 5
  }

  tags = {
    Name        = "${var.project}-wp-tg"
    Environment = var.environment
  }
}

# Target Group for Microservice
resource "aws_lb_target_group" "microservice" {
  name        = "${var.project}-ms-tg"
  port        = var.microservice_target_group_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 35
    matcher            = "200,301,302"
    path               = "/api/health"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 30
    unhealthy_threshold = 5
  }

  tags = {
    Name        = "${var.project}-ms-tg"
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
      message_body = "Please use wordpress.akshat.cloud or microservice.akshat.cloud"
      status_code  = "404"
    }
  }
}

# HTTPS Listener Rule for WordPress
resource "aws_lb_listener_rule" "wordpress" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress.arn
  }

  condition {
    host_header {
      values = ["wordpress.${var.domain_name}"]
    }
  }
}

# HTTPS Listener Rule for Microservice
resource "aws_lb_listener_rule" "microservice" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.microservice.arn
  }

  condition {
    host_header {
      values = ["microservice.${var.domain_name}"]
    }
  }
}

# HTTP Listener - Redirect to HTTPS
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