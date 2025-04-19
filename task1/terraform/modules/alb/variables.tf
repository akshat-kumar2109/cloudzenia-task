variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate to use for HTTPS"
  type        = string
}

variable "wordpress_target_group_port" {
  description = "Port for WordPress target group"
  type        = number
  default     = 80
}

variable "microservice_target_group_port" {
  description = "Port for microservice target group"
  type        = number
  default     = 3000
} 