output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the ALB"
  value       = aws_lb.main.zone_id
}

output "wordpress_target_group_arn" {
  description = "ARN of the WordPress target group"
  value       = aws_lb_target_group.wordpress.arn
}

output "microservice_target_group_arn" {
  description = "ARN of the microservice target group"
  value       = aws_lb_target_group.microservice.arn
} 