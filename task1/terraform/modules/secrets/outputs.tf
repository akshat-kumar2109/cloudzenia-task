output "secret_arn" {
  description = "ARN of the RDS credentials secret"
  value       = aws_secretsmanager_secret.rds_credentials.arn
}

output "secret_name" {
  description = "Name of the RDS credentials secret"
  value       = aws_secretsmanager_secret.rds_credentials.name
}

output "secrets_policy_json" {
  description = "IAM policy document for accessing secrets"
  value       = data.aws_iam_policy_document.secrets_access.json
} 