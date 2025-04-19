# Create the hosted zone
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name        = var.domain_name
    Environment = var.environment
  }
}

# WordPress subdomain
resource "aws_route53_record" "wordpress" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "wordpress.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id               = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Microservice subdomain
resource "aws_route53_record" "microservice" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "microservice.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id               = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Root domain record
resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id               = var.alb_zone_id
    evaluate_target_health = true
  }
} 