locals {
  name = "${var.project}-${var.environment}"
}

resource "aws_db_subnet_group" "main" {
  name        = "${local.name}-subnet-group"
  description = "Database subnet group for ${local.name}"
  subnet_ids  = var.subnet_ids

  tags = {
    Name        = "${local.name}-subnet-group"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_db_instance" "main" {
  identifier = "${local.name}-mysql"

  engine               = "mysql"
  engine_version       = "8.0"
  instance_class      = var.instance_class
  allocated_storage   = var.allocated_storage
  storage_type        = "gp2"
  storage_encrypted   = true

  db_name  = var.database_name
  username = var.master_username
  password = var.master_password

  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  multi_az               = var.multi_az
  publicly_accessible    = false

  backup_retention_period = var.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  auto_minor_version_upgrade = true
  allow_major_version_upgrade = false

  deletion_protection = false
  skip_final_snapshot = true
  final_snapshot_identifier = "${local.name}-final-snapshot"

  performance_insights_enabled = false
  
  tags = {
    Name        = "${local.name}-mysql"
    Environment = var.environment
    Project     = var.project
  }
}

# Null resource to disable RDS deletion protection before destroy
resource "null_resource" "disable_rds_deletion_protection" {
  triggers = {
    db_identifier = aws_db_instance.main.identifier
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
#!/bin/bash
set -e

echo "Disabling deletion protection for RDS instance: ${self.triggers.db_identifier}"
aws rds modify-db-instance \
    --db-instance-identifier ${self.triggers.db_identifier} \
    --no-deletion-protection \
    --apply-immediately

echo "Waiting for RDS modification to complete..."
aws rds wait db-instance-available --db-instance-identifier ${self.triggers.db_identifier}
EOF
  }

  depends_on = [aws_db_instance.main]
} 