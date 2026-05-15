terraform {
  required_version = ">=1.6.0"
  required_providers {
    aws ={
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

#create vpc
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "${var.project_name}-vpc-${var.environment}"
    Environment = var.environment
  }
}

#create public subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
    Environment = var.environment
    Tier = "Public"
  }
}

#create private subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.main.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
    Environment = var.environment
    Tier = "Private"
  }
  
}

#create database subnets
resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidrs)

  vpc_id = aws_vpc.main.id
  cidr_block = var.database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-database-subnet-${count.index + 1}"
    Environment = var.environment
    Tier = "Database"
  }
}

#create internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw-${var.environment}"
    Environment = var.environment
  }
}

#create public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt-${var.environment}"
    Environment = var.environment
  }
}

#associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

#EIP for NAT gateway
resource "aws_eip" "nat" {
  count = var.single_nat_gateway ? 1 : length(aws_subnet.public)
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${count.index + 1}"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

#create NAT gateway
resource "aws_nat_gateway" "main" { 
  count = var.single_nat_gateway ? 1 : length(aws_subnet.public)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-nat-gw-${count.index + 1}"
    Environment = var.environment
  }

  depends_on = [ aws_internet_gateway.main ]
}

#create private route tables and associate with private subnets
resource "aws_route_table" "private" {
  count  = var.single_nat_gateway ? 1 : length(var.private_subnet_cidrs)
    vpc_id = aws_vpc.main.id

    route {
      cidr_block = "0.0.0.0/0"
nat_gateway_id = aws_nat_gateway.main[var.single_nat_gateway ? 0 : count.index].id
    }

    tags = {
      Name = "${var.project_name}-private-rt-${count.index + 1}"
      Environment = var.environment
    }
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
  
}

#create database route tables and associate with database subnets
resource "aws_route_table" "database" {
    vpc_id = aws_vpc.main.id
    tags = {
      Name = "${var.project_name}-database-rt"
      Environment = var.environment
    }  
} 

resource "aws_route_table_association" "database" {
  count = length(var.database_subnet_cidrs)

  subnet_id = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}