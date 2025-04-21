# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project}-${var.environment}-alb-sg"
    Environment = var.environment
  }
}

# Ingress and Egress rules for ALB Security Group
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  ip_protocol      = "tcp"
  description       = "HTTP from anywhere"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  ip_protocol      = "tcp"
  description       = "HTTPS from anywhere"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_egress" {
  security_group_id = aws_security_group.alb.id
  ip_protocol      = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# EC2 Security Group
resource "aws_security_group" "ec2" {
  name        = "${var.project}-${var.environment}-ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project}-${var.environment}-ec2-sg"
    Environment = var.environment
  }
}

# Ingress and Egress rules for EC2 Security Group
resource "aws_vpc_security_group_ingress_rule" "ec2_http_from_alb" {
  security_group_id            = aws_security_group.ec2.id
  ip_protocol                 = "tcp"
  description                 = "HTTP from ALB"
  from_port                   = 80
  to_port                     = 80
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_ingress_rule" "ec2_http_direct" {
  security_group_id = aws_security_group.ec2.id
  ip_protocol      = "tcp"
  description       = "HTTP direct access"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "ec2_https_from_alb" {
  security_group_id            = aws_security_group.ec2.id
  ip_protocol                 = "tcp"
  description                 = "HTTPS from ALB"
  from_port                   = 443
  to_port                     = 443
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_ingress_rule" "ec2_ssh_from_jumpbox" {
  security_group_id            = aws_security_group.ec2.id
  ip_protocol                 = "tcp"
  description                 = "SSH from Jumpbox"
  from_port                   = 22
  to_port                     = 22
  referenced_security_group_id = var.jumpbox_security_group_id
}

resource "aws_vpc_security_group_egress_rule" "ec2_egress" {
  security_group_id = aws_security_group.ec2.id
  ip_protocol      = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
