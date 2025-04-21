# Network Module
module "network" {
  source = "./modules/network"

  environment        = var.environment
  project            = var.project
  vpc_cidr           = var.vpc_cidr
  azs                = var.availability_zones
  private_subnets    = var.private_subnet_cidrs
  public_subnets     = var.public_subnet_cidrs
  enable_nat_gateway = true
  single_nat_gateway = true
}

# Security Groups Module
module "security" {
  source = "./modules/security"

  environment = var.environment
  project     = var.project
  vpc_id      = module.network.vpc_id
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  environment       = var.environment
  project           = var.project
  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.private_subnets
  security_group_id = module.security.rds_security_group_id

  instance_class  = var.rds_instance_class
  database_name   = var.rds_database_name
  master_username = var.rds_master_username
  master_password = var.rds_master_password

  multi_az                = var.rds_multi_az
  backup_retention_period = var.rds_backup_retention_period

  depends_on = [module.network]
}

# Secrets Manager Module
module "secrets" {
  source = "./modules/secrets"

  environment       = var.environment
  project           = var.project
  rds_username      = module.rds.username
  rds_password      = var.rds_master_password
  rds_database_name = module.rds.db_name
  rds_host          = module.rds.endpoint
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"

  environment      = var.environment
  project          = var.project
  repository_names = ["wordpress", "microservice"]
}

# Docker Build and Push
resource "null_resource" "docker_build_push" {
  depends_on = [module.ecr]

  triggers = {
    ecr_repository_urls = join(",", values(module.ecr.repository_urls))
  }

  provisioner "local-exec" {
    working_dir = path.root
    command = <<-EOT
      # Login to ECR
      aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${split("/", module.ecr.repository_urls["wordpress"])[0]}

      # Build and push microservice image
      cd ../node-app
      docker build -t ${module.ecr.repository_urls["microservice"]}:latest .
      docker push ${module.ecr.repository_urls["microservice"]}:latest
      cd ${path.root}

      # Pull and push WordPress image
      docker pull wordpress:6.8.0-php8.1-apache
      docker tag wordpress:6.8.0-php8.1-apache ${module.ecr.repository_urls["wordpress"]}:latest
      docker push ${module.ecr.repository_urls["wordpress"]}:latest
    EOT
  }
}

# Rebuild and Push Microservice
resource "null_resource" "rebuild_microservice" {
  depends_on = [null_resource.docker_build_push]

  triggers = {
    app_file_hash = filemd5("${path.root}/../../task1/node-app/server.js")
  }

  provisioner "local-exec" {
    working_dir = path.root
    command = <<-EOT
      # Login to ECR
      aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${split("/", module.ecr.repository_urls["wordpress"])[0]}

      # Build and push microservice image
      cd ../node-app
      docker build -t ${module.ecr.repository_urls["microservice"]}:latest .
      docker push ${module.ecr.repository_urls["microservice"]}:latest
    EOT
  }
}

# ALB Module
module "alb" {
  source = "./modules/alb"

  project           = var.project
  environment       = var.environment
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnets
  certificate_arn   = module.acm.certificate_arn
  domain_name       = var.domain_name
}

# ECS Module
module "ecs" {
  depends_on = [null_resource.docker_build_push, null_resource.rebuild_microservice, module.secrets]
  source = "./modules/ecs"

  environment       = var.environment
  project           = var.project
  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.private_subnets
  security_group_id = module.security.ecs_tasks_security_group_id

  wordpress_target_group_arn    = module.alb.wordpress_target_group_arn
  microservice_target_group_arn = module.alb.microservice_target_group_arn

  wordpress_image    = "${module.ecr.repository_urls["wordpress"]}:latest"
  microservice_image = "${module.ecr.repository_urls["microservice"]}:latest"

  secrets_policy_json = module.secrets.secrets_policy_json
  rds_secret_arn      = module.secrets.secret_arn

  wordpress_cpu       = var.wordpress_cpu
  wordpress_memory    = var.wordpress_memory
  microservice_cpu    = var.microservice_cpu
  microservice_memory = var.microservice_memory

  wordpress_desired_count    = var.wordpress_desired_count
  microservice_desired_count = var.microservice_desired_count
  wordpress_max_count        = var.wordpress_max_count
  wordpress_min_count        = var.wordpress_min_count
  microservice_max_count     = var.microservice_max_count
  microservice_min_count     = var.microservice_min_count
}

module "acm" {
  source = "./modules/acm"

  domain_name            = "akshat.cloud"
  environment           = var.environment
  private_key_path      = var.private_key_path
  certificate_path      = var.certificate_path
  certificate_chain_path = var.certificate_chain_path

  tags = {
    ManagedBy = "Terraform"
    Project   = "akshat.cloud"
  }
}

# module "route53" {
#   source = "./modules/route53"

#   domain_name   = var.domain_name
#   environment   = var.environment
#   alb_dns_name = module.alb.alb_dns_name
#   alb_zone_id  = module.alb.alb_zone_id
# }
