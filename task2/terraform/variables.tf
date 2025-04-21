variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the application"
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
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "private_key_path" {
  description = "Path to SSL private key file"
  type        = string
}

variable "certificate_path" {
  description = "Path to SSL certificate file"
  type        = string
}

variable "certificate_chain_path" {
  description = "Path to SSL certificate chain file"
  type        = string
}

variable "my_ip_cidr" {
  description = "Your IP address in CIDR notation (e.g., 1.2.3.4/32)"
  type        = string
} 

variable "certificate_arn" {
  description = "ARN of the SSL certificate"
  type        = string
}