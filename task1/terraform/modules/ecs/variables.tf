variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ECS will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ECS tasks"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "wordpress_target_group_arn" {
  description = "ARN of the WordPress target group"
  type        = string
}

variable "microservice_target_group_arn" {
  description = "ARN of the microservice target group"
  type        = string
}

variable "wordpress_image" {
  description = "WordPress container image"
  type        = string
}

variable "microservice_image" {
  description = "Microservice container image"
  type        = string
}

variable "wordpress_container_port" {
  description = "Port for WordPress container"
  type        = number
  default     = 80
}

variable "microservice_container_port" {
  description = "Port for microservice container"
  type        = number
  default     = 3000
}

variable "secrets_policy_json" {
  description = "IAM policy JSON for accessing secrets"
  type        = string
}

variable "rds_secret_arn" {
  description = "ARN of the RDS secret"
  type        = string
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

variable "microservice_max_count" {
  description = "Maximum count of microservice tasks"
  type        = number
  default     = 4
}

variable "wordpress_min_count" {
  description = "Minimum count of WordPress tasks"
  type        = number
  default     = 1
}

variable "microservice_min_count" {
  description = "Minimum count of microservice tasks"
  type        = number
  default     = 1
} 