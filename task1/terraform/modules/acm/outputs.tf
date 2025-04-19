output "certificate_arn" {
  description = "ARN of the imported certificate"
  value       = aws_acm_certificate.cert.arn
}

output "certificate_domain" {
  description = "Domain name of the certificate"
  value       = var.domain_name
}

output "zone_id" {
  description = "ID of the Route53 hosted zone"
  value       = aws_route53_zone.main.zone_id
} 