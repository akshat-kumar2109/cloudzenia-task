output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.imported.arn
}

output "zone_id" {
  description = "ID of the Route53 hosted zone"
  value       = aws_route53_zone.imported.zone_id
}

output "name_servers" {
  description = "Name servers for the Route53 hosted zone"
  value       = aws_route53_zone.imported.name_servers
} 