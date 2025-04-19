variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Base domain name"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB"
  type        = string
}

variable "alb_zone_id" {
  description = "Zone ID of the ALB"
  type        = string
}

variable "zone_id" {
  description = "ID of the Route53 hosted zone"
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