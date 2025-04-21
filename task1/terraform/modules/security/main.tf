locals {
  name = "${var.project}-${var.environment}"
}

resource "aws_security_group" "alb" {
  name_prefix = "${local.name}-alb-"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${local.name}-alb-sg"
    Environment = var.environment
    Project     = var.project
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${local.name}-ecs-tasks-"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${local.name}-ecs-tasks-sg"
    Environment = var.environment
    Project     = var.project
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "${local.name}-rds-"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${local.name}-rds-sg"
    Environment = var.environment
    Project     = var.project
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ALB Ingress Rules
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from anywhere"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.alb_ingress_cidr_blocks[0] # repeat if more
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from anywhere (for redirect)"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.alb_ingress_cidr_blocks[0]
}

# ECS Ingress Rules
resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb_wordpress" {
  security_group_id            = aws_security_group.ecs_tasks.id
  description                  = "WordPress traffic from ALB"
  from_port                    = var.wordpress_container_port
  to_port                      = var.wordpress_container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_ingress_rule" "ecs_wordpress_public" {
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "WordPress traffic"
  from_port         = var.wordpress_container_port
  to_port           = var.wordpress_container_port
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "ecs_microservice_public" {
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "Microservice traffic"
  from_port         = var.microservice_container_port
  to_port           = var.microservice_container_port
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb_microservice" {
  security_group_id            = aws_security_group.ecs_tasks.id
  description                  = "Microservice traffic from ALB"
  from_port                    = var.microservice_container_port
  to_port                      = var.microservice_container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

# RDS Ingress Rule
resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs" {
  security_group_id            = aws_security_group.rds.id
  description                  = "MySQL from ECS tasks"
  from_port                    = var.rds_port
  to_port                      = var.rds_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_tasks.id
}

# ALB Egress
resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ECS Egress
resource "aws_vpc_security_group_egress_rule" "ecs_all" {
  security_group_id = aws_security_group.ecs_tasks.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# RDS Egress
resource "aws_vpc_security_group_egress_rule" "rds_all" {
  security_group_id = aws_security_group.rds.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}