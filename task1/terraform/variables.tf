variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"  # Change this to your preferred region
}

variable "role_arn" {
  description = "ARN of the IAM role to assume"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "rds_database_name" {
  description = "Name of the RDS database"
  type        = string
}

variable "rds_master_username" {
  description = "Master username for RDS"
  type        = string
}

variable "rds_master_password" {
  description = "Master password for RDS"
  type        = string
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

variable "rds_backup_retention_period" {
  description = "Number of days to retain RDS backups"
  type        = number
  default     = 7
}

variable "wordpress_cpu" {
  description = "CPU units for WordPress container"
  type        = number
  default     = 256
}

variable "wordpress_memory" {
  description = "Memory for WordPress container"
  type        = number
  default     = 512
}

variable "microservice_cpu" {
  description = "CPU units for microservice container"
  type        = number
  default     = 256
}

variable "microservice_memory" {
  description = "Memory for microservice container"
  type        = number
  default     = 512
}

variable "wordpress_desired_count" {
  description = "Desired count of WordPress tasks"
  type        = number
  default     = 2
}

variable "microservice_desired_count" {
  description = "Desired count of microservice tasks"
  type        = number
  default     = 2
}

variable "wordpress_max_count" {
  description = "Maximum count of WordPress tasks"
  type        = number
  default     = 4
}

variable "wordpress_min_count" {
  description = "Minimum count of WordPress tasks"
  type        = number
  default     = 1
}

variable "microservice_max_count" {
  description = "Maximum count of microservice tasks"
  type        = number
  default     = 4
}

variable "microservice_min_count" {
  description = "Minimum count of microservice tasks"
  type        = number
  default     = 1
}

variable "private_key_path" {
  description = "Path to the private key file for the SSL certificate"
  type        = string
}

variable "certificate_path" {
  description = "Path to the SSL certificate file"
  type        = string
}

variable "certificate_chain_path" {
  description = "Path to the SSL certificate chain file"
  type        = string
}
