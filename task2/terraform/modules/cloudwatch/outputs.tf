output "log_group_names" {
  description = "Names of the CloudWatch log groups"
  value       = aws_cloudwatch_log_group.nginx_access.name
} 