variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the security group"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "domain_name" {
  description = "Base domain name"
  type        = string
}

variable "alb_target_group_arns" {
  description = "List of ALB target group ARNs"
  type        = list(string)
}

variable "ecr_url" {
  description = "URL of the ECR repository"
  type        = string
} 