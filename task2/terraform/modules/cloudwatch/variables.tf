variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "ec2_instances" {
  description = "List of EC2 instances with their details"
  type = list(object({
    id         = string
    private_ip = string
    public_ip  = string
  }))
} 