resource "aws_acm_certificate" "cert" {
  private_key       = file("${path.root}/certs/privkey.pem")
  certificate_body  = file("${path.root}/certs/cert.pem")
  certificate_chain = file("${path.root}/certs/fullchain.pem")

  tags = merge({
    Name        = "${var.domain_name}-certificate"
    Environment = var.environment
    Domain      = var.domain_name
  }, var.tags)
} 