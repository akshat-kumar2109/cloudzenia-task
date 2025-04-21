# AWS Infrastructure with WordPress and Microservice

This project sets up a production-grade AWS infrastructure running WordPress and a Node.js microservice using AWS ECS Fargate, Application Load Balancer, RDS, and other AWS services.

## Architecture Overview

### Components
- **VPC** with public and private subnets across multiple availability zones
- **Application Load Balancer** for routing traffic to services
- **ECS Fargate** for running containerized applications
- **RDS MySQL** for WordPress database
- **ECR** for storing Docker images
- **Secrets Manager** for storing sensitive information
- **ACM** for SSL/TLS certificate management
- **Security Groups** for network security

### Applications
1. **WordPress**
   - Runs on ECS Fargate
   - Uses RDS MySQL database
   - Accessible via wordpress.yourdomain.com

2. **Node.js Microservice**
   - Simple Express.js application
   - Health check endpoint at /api/health
   - Main endpoint at /api
   - Accessible via microservice.yourdomain.com

## Prerequisites

1. AWS CLI installed and configured
2. Terraform installed (version 1.0.0 or later)
3. Docker installed
4. Domain name and SSL certificate
5. IAM role with necessary permissions

## Infrastructure Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
cd task1
```

### 2. Configure Variables
Create a `terraform.tfvars` file in the terraform directory:

```hcl
# AWS Configuration
aws_region = "us-east-1"
role_arn   = "arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_ROLE_NAME"

# Project Information
project     = "your-project"
environment = "production"

# Network Configuration
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]

# Domain Configuration
domain_name = "yourdomain.com"

# RDS Configuration
rds_instance_class    = "db.t3.micro"
rds_database_name     = "wordpress"
rds_master_username   = "admin"
rds_master_password   = "your-secure-password"
rds_multi_az         = false
rds_backup_retention_period = 7

# Container Resources
wordpress_cpu       = 256
wordpress_memory    = 512
microservice_cpu    = 256
microservice_memory = 512

# Service Scaling
wordpress_desired_count    = 2
wordpress_min_count       = 1
wordpress_max_count       = 4
microservice_desired_count = 2
microservice_min_count    = 1
microservice_max_count    = 4

# SSL Certificate
certificate_path      = "path/to/certificate.pem"
private_key_path     = "path/to/private-key.pem"
certificate_chain_path = "path/to/certificate-chain.pem"
```

### 3. Initialize Terraform
```bash
cd terraform
terraform init
```

### 4. Apply Infrastructure
```bash
terraform plan
terraform apply
```

## Infrastructure Components Details

### Networking
- VPC with public and private subnets
- NAT Gateway for private subnet internet access
- Internet Gateway for public subnet access

### Security
- ALB Security Group: Allows inbound HTTP(80) and HTTPS(443)
- ECS Tasks Security Group: Allows inbound traffic from ALB
- RDS Security Group: Allows inbound MySQL(3306) from ECS tasks

### Container Services
- WordPress container runs on port 80
- Microservice container runs on port 3000
- Both services use Fargate launch type
- Auto-scaling based on CPU and Memory utilization

### Database
- RDS MySQL instance in private subnet
- Automated backups
- Credentials stored in AWS Secrets Manager

### Load Balancer
- Application Load Balancer with HTTP to HTTPS redirect
- Host-based routing:
  - wordpress.yourdomain.com → WordPress service
  - microservice.yourdomain.com → Node.js service

## Monitoring and Maintenance

### Logs
- Container logs available in CloudWatch Logs
- Groups:
  - /ecs/[project]-[environment]/wordpress
  - /ecs/[project]-[environment]/microservice

### Scaling
- Services scale automatically based on CPU and Memory utilization
- Target tracking policies maintain 70% utilization

### Health Checks
- WordPress: Checks /wp-admin/install.php
- Microservice: Checks /api/health
- Grace period: 120 seconds

## Security Considerations
1. All sensitive data stored in AWS Secrets Manager
2. Private resources in private subnets
3. Security groups with minimum required access
4. HTTPS enforced with HTTP to HTTPS redirect
5. Regular automated backups of RDS

## Cost Optimization
1. Fargate Spot can be used for cost savings
2. RDS multi-AZ optional for development
3. NAT Gateway shared across AZs
4. Auto-scaling based on demand

## Cleanup
To destroy the infrastructure:
```bash
terraform destroy
```

## Notes
- Ensure your domain's DNS is properly configured
- Initial WordPress setup needs to be completed via the web interface
- Monitor CloudWatch logs for application issues
- Regular backup verification recommended
- Keep terraform.tfvars secure and never commit to version control 