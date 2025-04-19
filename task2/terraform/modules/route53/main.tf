# ALB Docker Record
resource "aws_route53_record" "alb_docker" {
  zone_id = var.zone_id
  name    = "ec2-alb-docker.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# ALB Instance Record
resource "aws_route53_record" "alb_instance" {
  zone_id = var.zone_id
  name    = "ec2-alb-instance.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# EC2 Docker Instance Records
resource "aws_route53_record" "docker_instances" {
  count   = 2
  zone_id = var.zone_id
  name    = "ec2-docker${count.index + 1}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# EC2 Instance Records
resource "aws_route53_record" "instances" {
  count   = 2
  zone_id = var.zone_id
  name    = "ec2-instance${count.index + 1}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
} 