# Create key pair from public key
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project}-${var.environment}-deployer-key"
  public_key = file("${path.root}/deployer-key.pub")
}

# EC2 Instances
resource "aws_instance" "main" {
  count = 2

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  subnet_id                   = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name

  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    instance_number      = count.index + 1
    domain_name         = var.domain_name
    ecr_url            = var.ecr_url
    aws_region         = data.aws_region.current.name
    private_key       = file("/home/akshat/Desktop/cloudzenia-task/task2/terraform/certs/privkey.pem")
    certificate = file("/home/akshat/Desktop/cloudzenia-task/task2/terraform/certs/fullchain.pem")
  })

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  depends_on = [var.nat_gateway_id] # Ensure NAT Gateway is ready

  tags = {
    Name        = "${var.project}-${var.environment}-instance-${count.index + 1}"
    Environment = var.environment
  }
}

# Elastic IPs
resource "aws_eip" "main" {
  count  = 2
  domain = "vpc"

  tags = {
    Name        = "${var.project}-${var.environment}-eip-${count.index + 1}"
    Environment = var.environment
  }
}

# EIP Association
resource "aws_eip_association" "main" {
  count         = 2
  instance_id   = aws_instance.main[count.index].id
  allocation_id = aws_eip.main[count.index].id
}

# Get current AWS region
data "aws_region" "current" {}

# Latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Instance IAM Role
resource "aws_iam_role" "instance_role" {
  name = "${var.project}-${var.environment}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# CloudWatch Agent Policy
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# SSM Policy
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Logs Policy
resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${var.project}-${var.environment}-cloudwatch-logs"
  role = aws_iam_role.instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = ["arn:aws:logs:*:*:*"]
      }
    ]
  })
}

# ECR Pull Policy
resource "aws_iam_role_policy" "ecr_pull" {
  name = "${var.project}-${var.environment}-ecr-pull"
  role = aws_iam_role.instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken"
        ]
        Resource = ["*"]
      }
    ]
  })
}

# Instance Profile
resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.project}-${var.environment}-instance-profile"
  role = aws_iam_role.instance_role.name
}

# Target Group Attachments for Instance
resource "aws_lb_target_group_attachment" "instance" {
  count            = 2
  target_group_arn = var.alb_target_group_arns[0]  # Instance target group
  target_id        = aws_instance.main[count.index].id
  port             = 80
} 