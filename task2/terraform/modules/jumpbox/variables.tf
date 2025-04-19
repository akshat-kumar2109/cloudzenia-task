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

variable "public_subnet_id" {
  description = "ID of the public subnet where the jumpbox will be created"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair to use for the jumpbox"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the jumpbox"
  type        = string
  default     = "t3.micro"
}

variable "allowed_ssh_cidr_blocks" {
  description = "List of CIDR blocks allowed to SSH into the jumpbox"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Note: You should restrict this to your IP address in production
} 