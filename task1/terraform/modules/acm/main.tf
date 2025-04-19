resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = merge({
    Name        = "${var.domain_name}-zone"
    Environment = var.environment
  }, var.tags)
}

resource "aws_acm_certificate" "cert" {
  private_key       = file(var.private_key_path)
  certificate_body  = file(var.certificate_path)
  certificate_chain = file(var.certificate_chain_path)

  tags = merge({
    Name        = "${var.domain_name}-certificate"
    Environment = var.environment
    Domain      = var.domain_name
  }, var.tags)
} 