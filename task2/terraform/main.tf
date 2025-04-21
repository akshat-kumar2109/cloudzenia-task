# Create key pair from public key
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("${path.root}/deployer-key.pub")
}

# Network Module
module "network" {
  source = "./modules/network"

  environment     = var.environment
  project         = var.project
  vpc_cidr        = var.vpc_cidr
  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs
}

# Jumpbox Module
module "jumpbox" {
  source = "./modules/jumpbox"

  environment             = var.environment
  project                 = var.project
  vpc_id                  = module.network.vpc_id
  public_subnet_id        = module.network.public_subnets[0]
  key_name                = aws_key_pair.deployer.key_name
  allowed_ssh_cidr_blocks = [var.my_ip_cidr]
}

# Security Groups Module
module "security" {
  source = "./modules/security"

  environment               = var.environment
  project                   = var.project
  vpc_id                    = module.network.vpc_id
  jumpbox_security_group_id = module.jumpbox.jumpbox_security_group_id
}

# ACM Module for SSL Certificate
# module "acm" {
#   source = "../../task1/terraform/modules/acm"

#   domain_name            = var.domain_name
#   environment            = var.environment
#   private_key_path       = var.private_key_path
#   certificate_path       = var.certificate_path
#   certificate_chain_path = var.certificate_chain_path
#   tags = {
#     Environment = var.environment
#   }
# }

# ECR Module
module "ecr" {
  source = "./modules/ecr"

  environment = var.environment
  project     = var.project
}

# ALB Module
module "alb" {
  source = "./modules/alb"

  project           = var.project
  environment       = var.environment
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnets
  security_group_id = module.security.alb_security_group_id
  certificate_arn   = var.certificate_arn
  domain_name       = var.domain_name
  ec2_instance1_id  = module.ec2.instances[0].id
  ec2_instance2_id  = module.ec2.instances[1].id
}

# EC2 Instances Module
module "ec2" {
  source = "./modules/ec2"

  environment            = var.environment
  project                = var.project
  vpc_id                 = module.network.vpc_id
  private_subnet_ids     = module.network.private_subnets
  security_group_id      = module.security.ec2_security_group_id
  instance_type          = var.instance_type
  domain_name            = var.domain_name
  ecr_url                = module.ecr.repository_url
  private_key_path       = var.private_key_path
  certificate_chain_path = var.certificate_chain_path
  nat_gateway_id         = module.network.nat_gateway_id
  alb_target_group_arns = [
    module.alb.instance_target_group_arn,
    module.alb.docker_target_group_arn
  ]
}

# Route53 Module
# module "route53" {
#   source = "./modules/route53"

#   domain_name    = var.domain_name
#   environment    = var.environment
#   alb_dns_name   = module.alb.alb_dns_name
#   alb_zone_id    = module.alb.alb_zone_id
#   zone_id        = module.acm.zone_id
#   ec2_instances  = module.ec2.instances
# }

# CloudWatch Module
module "cloudwatch" {
  source = "./modules/cloudwatch"

  environment   = var.environment
  project       = var.project
  ec2_instances = module.ec2.instances
} 