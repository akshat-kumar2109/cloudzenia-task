variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "alb_ingress_cidr_blocks" {
  description = "List of CIDR blocks for ALB ingress"
  type        = list(string)
  default     = ["0.0.0.0/0"]
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

variable "rds_port" {
  description = "Port for RDS instance"
  type        = number
  default     = 3306
} 