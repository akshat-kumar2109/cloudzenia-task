# Network outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.network.public_subnets
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.network.private_subnets
}

# EC2 outputs
output "ec2_instance_ids" {
  description = "IDs of EC2 instances"
  value       = module.ec2.instances[*].id
}

output "ec2_private_ips" {
  description = "Private IPs of EC2 instances"
  value       = module.ec2.instances[*].private_ip
}

# ALB outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "target_group_arns" {
  description = "ARNs of target groups"
  value = {
    instance = module.alb.instance_target_group_arn
  }
}

# ECR outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

# Route53 outputs
output "domain_endpoints" {
  description = "Domain endpoints for the application"
  value = {
    main_domain = "https://${var.domain_name}"
    www_domain  = "https://www.${var.domain_name}"
  }
}

# Security Group outputs
output "security_group_ids" {
  description = "IDs of the security groups"
  value = {
    alb = module.security.alb_security_group_id
    ec2 = module.security.ec2_security_group_id
  }
}

# CloudWatch outputs
output "cloudwatch_log_groups" {
  description = "Names of CloudWatch log groups"
  value       = module.cloudwatch.log_group_names
} 