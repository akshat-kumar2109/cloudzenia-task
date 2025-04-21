# AWS Infrastructure with EC2 Instances and Docker

This project sets up a production-grade AWS infrastructure with EC2 instances running Docker containers, Application Load Balancer, and associated networking components.

## Architecture Overview

### Components
- **VPC** with public and private subnets across multiple availability zones
- **Application Load Balancer** for traffic distribution
- **EC2 Instances** in private subnets running Docker containers
- **Jumpbox/Bastion Host** for secure SSH access
- **ECR** for storing Docker images
- **CloudWatch** for monitoring and logging
- **Security Groups** for network security
- **NAT Gateway** for outbound internet access from private subnets

### Infrastructure Design
1. **Network Layer**
   - VPC with public and private subnets
   - Internet Gateway for public subnets
   - NAT Gateway for private subnet internet access
   - Route tables for traffic management

2. **Security Layer**
   - Jumpbox in public subnet for secure SSH access
   - EC2 instances in private subnets
   - Security groups with least privilege access
   - SSH key pair for instance access

3. **Application Layer**
   - EC2 instances running Docker containers
   - Application Load Balancer for traffic distribution
   - Target groups for health monitoring
   - ECR for container image storage

4. **Monitoring Layer**
   - CloudWatch for instance monitoring
   - CloudWatch Logs for application logs
   - ALB access logs
   - Health checks and metrics

## Prerequisites

1. AWS CLI installed and configured
2. Terraform installed (version 1.0.0 or later)
3. Docker installed locally
4. SSH key pair for instance access
5. SSL certificate for HTTPS
6. Domain name (if using custom domain)

## Infrastructure Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
cd task2
```

### 2. Generate SSH Key Pair (if not exists)
```bash
ssh-keygen -t rsa -b 4096 -f terraform/deployer-key
```

### 3. Configure Variables
Create a `terraform.tfvars` file in the terraform directory:

```hcl
# AWS Configuration
aws_region = "us-east-1"

# Project Information
project     = "your-project"
environment = "production"

# Network Configuration
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]

# Security Configuration
my_ip_cidr = "YOUR_IP/32"  # Your IP address for SSH access

# Instance Configuration
instance_type = "t3.micro"

# Domain and SSL Configuration
domain_name = "yourdomain.com"
certificate_arn = "arn:aws:acm:region:account:certificate/certificate-id"
private_key_path = "path/to/private-key.pem"
certificate_path = "path/to/certificate.pem"
certificate_chain_path = "path/to/certificate-chain.pem"
```

### 4. Initialize Terraform
```bash
cd terraform
terraform init
```

### 5. Apply Infrastructure
```bash
terraform plan
terraform apply
```

## Infrastructure Components Details

### Networking
- VPC with public and private subnets
- NAT Gateway for private subnet internet access
- Internet Gateway for public subnet access
- Route tables for traffic management

### Security
- ALB Security Group: Allows inbound HTTP(80) and HTTPS(443)
- EC2 Security Group: Allows inbound traffic from ALB and Jumpbox
- Jumpbox Security Group: Allows inbound SSH from specified IP
- All instances use SSH key authentication

### Compute
- EC2 instances in private subnets
- Docker runtime environment
- Automatic container deployment
- Instance profile with ECR access

### Load Balancer
- Application Load Balancer in public subnets
- Target groups for instance and container traffic
- Health checks for high availability
- SSL/TLS termination

## Monitoring and Maintenance

### CloudWatch
- EC2 instance metrics
- Container logs
- ALB access logs
- Custom metrics and alarms

### Access
- SSH access via Jumpbox
- ALB for application access
- ECR for container management

### Backup and Recovery
- AMI backups recommended
- Container images in ECR
- Infrastructure as Code for disaster recovery

## Security Considerations
1. Instances in private subnets
2. SSH access only through Jumpbox
3. Security groups with minimum required access
4. HTTPS for all external traffic
5. Regular security patches

## Cost Optimization
1. Right-sized instances
2. Auto Scaling (can be added)
3. NAT Gateway sharing
4. CloudWatch logs retention policy

## Cleanup
To destroy the infrastructure:
```bash
terraform destroy
```

## Notes
- Update security group rules as needed
- Monitor CloudWatch metrics
- Regular security updates
- Backup EC2 instances
- Keep terraform.tfvars secure 