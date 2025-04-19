locals {
  name = "${var.project}-${var.environment}"
}

resource "random_string" "random" {
  length           = 5
  special          = false
  override_special = "/@£$"
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "${local.name}-rds-credentials-${random_string.random.result}"
  description = "RDS credentials for WordPress"

  tags = {
    Name        = "${local.name}-rds-credentials-${random_string.random.result}"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = var.rds_username
    password = var.rds_password
    dbname   = var.rds_database_name
    host     = var.rds_host
  })
}

# IAM Policy for ECS to access Secrets Manager
data "aws_iam_policy_document" "secrets_access" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [aws_secretsmanager_secret.rds_credentials.arn]
  }
} 