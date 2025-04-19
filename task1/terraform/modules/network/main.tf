locals {
  name = "${var.project}-${var.environment}"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name        = "${local.name}-vpc"
    Environment = var.environment
    Project     = var.project
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block             = var.public_subnets[count.index]
  availability_zone      = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.name}-public-${var.azs[count.index]}"
    Environment = var.environment
    Project     = var.project
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block       = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name        = "${local.name}-private-${var.azs[count.index]}"
    Environment = var.environment
    Project     = var.project
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${local.name}-igw"
    Environment = var.environment
    Project     = var.project
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnets)) : 0
  domain = "vpc"

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name        = "${local.name}-eip-${count.index + 1}"
    Environment = var.environment
    Project     = var.project
  }
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnets)) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name        = "${local.name}-nat-${count.index + 1}"
    Environment = var.environment
    Project     = var.project
  }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${local.name}-public-rt"
    Environment = var.environment
    Project     = var.project
  }
}

# Add route separately to avoid cycle
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table" "private" {
  count = length(var.private_subnets)

  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${local.name}-private-rt-${count.index + 1}"
    Environment = var.environment
    Project     = var.project
  }
}

# Add route separately to avoid cycle
resource "aws_route" "private_nat_gateway" {
  count = var.enable_nat_gateway ? length(var.private_subnets) : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = var.enable_nat_gateway ? (
    var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
  ) : null

  depends_on = [aws_nat_gateway.main]

  timeouts {
    create = "5m"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
} 