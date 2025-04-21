output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB"
  value       = aws_lb.main.zone_id
}

output "instance_target_group_arn" {
  description = "ARN of the Instance target group"
  value       = aws_lb_target_group.instance1.arn
}

output "docker_target_group_arn" {
  description = "ARN of the Docker target group"
  value       = aws_lb_target_group.instance2.arn
}
