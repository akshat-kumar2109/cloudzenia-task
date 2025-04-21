# AWS Infrastructure Projects

This repository contains two AWS infrastructure projects implemented using Terraform, demonstrating different approaches to hosting web applications.

## Task 1: ECS with ALB, RDS, and SecretsManager

### Overview
A containerized infrastructure running WordPress and a custom microservice using AWS ECS Fargate, with RDS for database storage and SecretsManager for secure credentials management.

### Components
1. **ECS Cluster & Services**
   - Private subnet deployment
   - Two services:
     - WordPress container
     - Custom Node.js microservice
   - Auto-scaling based on CPU and Memory
   - Task definitions with SecretsManager integration

2. **RDS Database**
   - MySQL database for WordPress
   - Private subnet deployment
   - Custom user credentials (non-rotating)
   - Automated backups
   - Secure connectivity

3. **Security**
   - SecretsManager for RDS credentials
   - IAM roles for ECS-SecretsManager access
   - Least privilege security groups
   - Private subnet isolation

4. **Load Balancing & Domain**
   - ALB in public subnets
   - SSL/TLS termination
   - HTTP to HTTPS redirect
   - Domain mappings:
     - wordpress.akshat.cloud
     - microservice.akshat.cloud

### Directory Structure
```
task1/
├── terraform/        # Infrastructure as Code
│   ├── modules/     # Terraform modules
│   └── main.tf      # Main configuration
├── node-app/        # Microservice application
│   ├── Dockerfile
│   └── server.js
└── README.md        # Detailed setup instructions
```

## Task 2: EC2 with Docker, NGINX, and Domain Mapping

### Overview
A traditional infrastructure using EC2 instances with Docker and NGINX, demonstrating multi-domain hosting and SSL configuration.

### Components
1. **EC2 Instances**
   - 2 instances in private subnets
   - Docker and NGINX installed
   - Custom application deployment

2. **Docker Configuration**
   - Container serving "Namaste from Container"
   - Internal port 8080
   - NGINX reverse proxy integration

3. **NGINX Setup**
   - Domain-based routing
   - Multiple domain configurations:
     - ec2-instance1.akshat.cloud → "Hello from Instance"
     - ec2-instance2.akshat.cloud → "Hello from Instance"
     - ec2-docker1.akshat.cloud → Docker container
     - ec2-docker2.akshat.cloud → Docker container

4. **Load Balancing & Domain**
   - ALB in public subnets
   - SSL/TLS termination
   - HTTP to HTTPS redirect
   - Domain mappings:
     - ec2-alb-docker.akshat.cloud
     - ec2-alb-instance.akshat.cloud

5. **Monitoring**
   - CloudWatch metrics for RAM utilization
   - NGINX access logs in CloudWatch
   - Custom metrics and alarms

### Directory Structure
```
task2/
├── terraform/        # Infrastructure as Code
│   ├── modules/     # Terraform modules
│   └── main.tf      # Main configuration
├── app/             # Application files
│   └── nginx/       # NGINX configurations
└── README.md        # Detailed setup instructions
```

## Key Differences

1. **Container Orchestration**
   - Task 1: Uses ECS Fargate for containerized applications
   - Task 2: Uses Docker directly on EC2 instances

2. **Application Hosting**
   - Task 1: Managed container service with auto-scaling
   - Task 2: Traditional EC2 instances with manual Docker management

3. **Database**
   - Task 1: Managed RDS instance
   - Task 2: No database requirement

4. **Security**
   - Task 1: SecretsManager and ECS task roles
   - Task 2: SSH key-based access and security groups

5. **Monitoring**
   - Task 1: ECS and RDS metrics
   - Task 2: Custom EC2 metrics and NGINX logs

## Prerequisites

1. AWS CLI configured
2. Terraform installed
3. Docker installed
4. Domain name (akshat.cloud)
5. SSL certificates
6. Basic understanding of:
   - AWS Services
   - Terraform
   - Docker
   - NGINX

## Getting Started

1. Clone the repository
2. Choose the task to implement
3. Follow the README in the respective task directory
4. Configure required variables
5. Apply the Terraform configuration

## Security Notes

1. Keep credentials secure
2. Use private subnets for sensitive resources
3. Implement least privilege access
4. Enable HTTPS only
5. Regular security updates

## Cost Optimization

1. Right-size resources
2. Use auto-scaling where applicable
3. Monitor resource usage
4. Clean up unused resources

## Support

For detailed setup instructions and troubleshooting:
1. Refer to individual task READMEs
2. Check AWS documentation
3. Review Terraform documentation 