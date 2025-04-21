locals {
  name = "${var.project}-${var.environment}"
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${local.name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${local.name}-cluster"
    Environment = var.environment
    Project     = var.project
  }
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.name}-ecs-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${local.name}-ecs-task-execution"
    Environment = var.environment
    Project     = var.project
  }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Add Secrets Manager access policy to task execution role
resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name = "${local.name}-secrets-access"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.rds_secret_arn
        ]
      }
    ]
  })
}

# ECS Task Role
resource "aws_iam_role" "ecs_task" {
  name = "${local.name}-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${local.name}-ecs-task"
    Environment = var.environment
    Project     = var.project
  }
}

# Attach Secrets Manager access policy to task role
resource "aws_iam_role_policy" "secrets_access" {
  name   = "${local.name}-secrets-access"
  role   = aws_iam_role.ecs_task.id
  policy = var.secrets_policy_json
}

# Data source for RDS secret
data "aws_secretsmanager_secret_version" "rds" {
  secret_id = var.rds_secret_arn
}

# WordPress Task Definition
resource "aws_ecs_task_definition" "wordpress" {
  family                   = "${local.name}-wordpress"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = var.wordpress_cpu
  memory                  = var.wordpress_memory
  execution_role_arn      = aws_iam_role.ecs_task_execution.arn
  task_role_arn           = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "wordpress"
      image = var.wordpress_image
      portMappings = [
        {
          containerPort = var.wordpress_container_port
          hostPort     = var.wordpress_container_port
          protocol     = "tcp"
        }
      ]
      environment = [
        {
          name  = "WORDPRESS_DB_HOST"
          value = jsondecode(data.aws_secretsmanager_secret_version.rds.secret_string)["host"]
        },
        {
          name  = "WORDPRESS_DB_USER"
          value = jsondecode(data.aws_secretsmanager_secret_version.rds.secret_string)["username"]
        },
        {
          name  = "WORDPRESS_DB_PASSWORD"
          value = jsondecode(data.aws_secretsmanager_secret_version.rds.secret_string)["password"]
        },
        {
          name  = "WORDPRESS_DB_NAME"
          value = jsondecode(data.aws_secretsmanager_secret_version.rds.secret_string)["dbname"]
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.wordpress_container_port}/wp-admin/install.php || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 120
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${local.name}/wordpress"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "wordpress"
        }
      }
      essential = true
    }
  ])

  tags = {
    Name        = "${local.name}-wordpress"
    Environment = var.environment
    Project     = var.project
  }
}

# Microservice Task Definition
resource "aws_ecs_task_definition" "microservice" {
  family                   = "${local.name}-microservice"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = var.microservice_cpu
  memory                  = var.microservice_memory
  execution_role_arn      = aws_iam_role.ecs_task_execution.arn
  task_role_arn           = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "microservice"
      image = var.microservice_image
      portMappings = [
        {
          containerPort = var.microservice_container_port
          hostPort     = var.microservice_container_port
          protocol     = "tcp"
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.microservice_container_port}/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 120
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${local.name}/microservice"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "microservice"
        }
      }
      essential = true
    }
  ])

  tags = {
    Name        = "${local.name}-microservice"
    Environment = var.environment
    Project     = var.project
  }
}

# WordPress Service
resource "aws_ecs_service" "wordpress" {
  name            = "${local.name}-wordpress"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.wordpress.arn
  desired_count   = var.wordpress_desired_count
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 120

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.wordpress_target_group_arn
    container_name   = "wordpress"
    container_port   = var.wordpress_container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = {
    Name        = "${local.name}-wordpress"
    Environment = var.environment
    Project     = var.project
  }
}

# Microservice Service
resource "aws_ecs_service" "microservice" {
  name            = "${local.name}-microservice"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.microservice.arn
  desired_count   = var.microservice_desired_count
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 120

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.microservice_target_group_arn
    container_name   = "microservice"
    container_port   = var.microservice_container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = {
    Name        = "${local.name}-microservice"
    Environment = var.environment
    Project     = var.project
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "wordpress" {
  name              = "/ecs/${local.name}/wordpress"
  retention_in_days = 30

  tags = {
    Name        = "${local.name}-wordpress-logs"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_cloudwatch_log_group" "microservice" {
  name              = "/ecs/${local.name}/microservice"
  retention_in_days = 30

  tags = {
    Name        = "${local.name}-microservice-logs"
    Environment = var.environment
    Project     = var.project
  }
}

# Auto Scaling for WordPress
resource "aws_appautoscaling_target" "wordpress" {
  max_capacity       = var.wordpress_max_count
  min_capacity       = var.wordpress_min_count
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.wordpress.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "wordpress_cpu" {
  name               = "${local.name}-wordpress-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.wordpress.resource_id
  scalable_dimension = aws_appautoscaling_target.wordpress.scalable_dimension
  service_namespace  = aws_appautoscaling_target.wordpress.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_appautoscaling_policy" "wordpress_memory" {
  name               = "${local.name}-wordpress-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.wordpress.resource_id
  scalable_dimension = aws_appautoscaling_target.wordpress.scalable_dimension
  service_namespace  = aws_appautoscaling_target.wordpress.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 70.0
  }
}

# Auto Scaling for Microservice
resource "aws_appautoscaling_target" "microservice" {
  max_capacity       = var.microservice_max_count
  min_capacity       = var.microservice_min_count
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.microservice.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "microservice_cpu" {
  name               = "${local.name}-microservice-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.microservice.resource_id
  scalable_dimension = aws_appautoscaling_target.microservice.scalable_dimension
  service_namespace  = aws_appautoscaling_target.microservice.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_appautoscaling_policy" "microservice_memory" {
  name               = "${local.name}-microservice-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.microservice.resource_id
  scalable_dimension = aws_appautoscaling_target.microservice.scalable_dimension
  service_namespace  = aws_appautoscaling_target.microservice.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 70.0
  }
}

data "aws_region" "current" {} 