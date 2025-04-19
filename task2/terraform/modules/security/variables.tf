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

variable "jumpbox_security_group_id" {
  description = "ID of the jumpbox security group"
  type        = string
} 