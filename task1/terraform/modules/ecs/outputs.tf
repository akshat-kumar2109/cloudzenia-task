output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "wordpress_service_name" {
  description = "Name of the WordPress ECS service"
  value       = aws_ecs_service.wordpress.name
}

output "microservice_service_name" {
  description = "Name of the microservice ECS service"
  value       = aws_ecs_service.microservice.name
}

output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task.arn
} 