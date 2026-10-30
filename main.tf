# Create a VPC
resource "aws_vpc" "ecs_learning_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"

  tags = {
    Name    = "${var.project_name}-vpc"
    Creator = var.creator_tag
  }
}

resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.ecs_learning_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-public-${count.index + 1}"
    Creator = var.creator_tag
    Tier    = "public"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  availability_zone = var.azs[count.index]
  cidr_block        = var.private_subnet_cidrs[count.index]
  vpc_id            = aws_vpc.ecs_learning_vpc.id
  tags = {
    Name    = "${var.project_name}-private-${count.index + 1}"
    Creator = var.creator_tag
    Tier    = "private"
  }
}

# ---------------------------
# Internet Gateway (for public subnets)
# ---------------------------
resource "aws_internet_gateway" "ecs_learning_igw" {
  vpc_id = aws_vpc.ecs_learning_vpc.id

  tags = {
    Name    = "${var.project_name}-igw"
    Creator = var.creator_tag
  }
}

# ---------------------------
# Public Route Table (routes 0.0.0.0/0 -> IGW)
# ---------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.ecs_learning_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs_learning_igw.id
  }

  tags = {
    Name    = "${var.project_name}-public-rt"
    Creator = var.creator_tag
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# ---------------------------
# Private Route Table (no internet route; S3 gateway endpoint adds its prefix-list route)
# ---------------------------
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.ecs_learning_vpc.id

  tags = {
    Name    = "${var.project_name}-private-rt"
    Creator = var.creator_tag
  }
}

resource "aws_route_table_association" "private_rt_assoc" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

## VPC Endpoints for ECS and ECR
resource "aws_security_group" "vpec_sg_ecs" {
  name        = "${var.app_name}-vpec_ecs_api-sg"
  description = "Security group for ECS task to reach ECR API"
  vpc_id      = aws_vpc.ecs_learning_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "vpec_sg_mongo" {
  name        = "${var.app_name}-vpec_mongo-sg"
  description = "Security group for MongoDB instance to reach VPC endpoints"
  vpc_id      = aws_vpc.ecs_learning_vpc.id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    # cidr_blocks = var.private_subnet_cidrs
    security_groups = [aws_security_group.ecs_task_sg.id]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "${var.app_name}-vpc-endpoint-sg"
  description = "Security group for Vpc"
  vpc_id      = aws_vpc.ecs_learning_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    
    security_groups = [aws_security_group.ecs_task_sg.id, aws_security_group.vpec_sg_mongo.id]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  }

resource "aws_vpc_endpoint" "all_vpc_endpoint" {
  vpc_id            = aws_vpc.ecs_learning_vpc.id
  for_each          = toset(["ecr.api", "ecr.dkr", "logs", "ssm", "ssmmessages", "ec2messages", "sts"])
  service_name      = "com.amazonaws.${var.aws_region}.${each.key}"
  vpc_endpoint_type = "Interface"
  security_group_ids = [ aws_security_group.vpc_endpoint_sg.id]
  subnet_ids        = aws_subnet.private_subnets[*].id
  private_dns_enabled = true
  tags = {
    Name    = "${var.project_name}-vpec-${each.key}"
    Creator = var.creator_tag
  }
}



resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.ecs_learning_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.public_rt.id, aws_route_table.private_rt.id]

  tags = {
    Name    = "${var.project_name}-vpec-s3"
    Creator = var.creator_tag
  }
}


