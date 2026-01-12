# terraform {
#   required_version = ">= 1.6.0"
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 5.0"
#     }
#   }
# }

provider "aws" {
  region = var.region
}

#########################
# AMI
#########################
data "aws_ami" "amazon" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_availability_zones" "azs" {}

#########################
# VPC
#########################
resource "aws_vpc" "grace" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "grace-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.grace.id
}

#########################
# SUBNETS
#########################
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.grace.id
  cidr_block              = ["10.0.1.0/24", "10.0.2.0/24"][count.index]
  availability_zone       = data.aws_availability_zones.azs.names[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "grace-public-${count.index + 1}" }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.grace.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.azs.names[count.index]
  tags = { Name = "grace-private-${count.index + 1}" }
}

#########################
# ROUTING
#########################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.grace.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.grace.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

#########################
# SECURITY GROUPS
#########################
resource "aws_security_group" "web" {
  name   = "grace-web"
  vpc_id = aws_vpc.grace.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db" {
  name   = "grace-db"
  vpc_id = aws_vpc.grace.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#########################
# EC2
#########################
resource "aws_instance" "nginx" {
  ami                         = data.aws_ami.amazon.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  tags = { Name = "grace-nginx" }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.key_name
  tags = { Name = "grace-backend" }
}

#########################
# RDS
#########################
resource "aws_db_subnet_group" "db" {
  name       = "grace-db-subnets"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_instance" "postgres" {
  identifier              = "grace-postgres"
  engine                  = "postgres"
  engine_version          = "14"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_name                 = "gracedb"
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.db.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  publicly_accessible     = false
  skip_final_snapshot     = true
}