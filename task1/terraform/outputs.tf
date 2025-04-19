output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "wordpress_endpoint" {
  description = "HTTP endpoint for WordPress application"
  value       = "http://${module.alb.alb_dns_name}/"
}

output "microservice_endpoint" {
  description = "HTTP endpoint for microservice application"
  value       = "http://${module.alb.alb_dns_name}/api"
}

output "microservice_health_endpoint" {
  description = "Health check endpoint for microservice"
  value       = "http://${module.alb.alb_dns_name}/api/health"
}

output "rds_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = module.rds.endpoint
}

output "ecr_repository_urls" {
  description = "URLs of the ECR repositories"
  value       = module.ecr.repository_urls
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "wordpress_service_name" {
  description = "Name of the WordPress ECS service"
  value       = module.ecs.wordpress_service_name
}

output "microservice_service_name" {
  description = "Name of the microservice ECS service"
  value       = module.ecs.microservice_service_name
}
