output "endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "username" {
  description = "Master username"
  value       = aws_db_instance.main.username
}

output "port" {
  description = "Database port"
  value       = aws_db_instance.main.port
}

output "arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.main.arn
} 