provider "aws" {
  region = var.region
}

####################
# VPC
####################
resource "aws_vpc" "grace" {
  cidr_block = var.vpc_cidr
  tags = { Name = "grace-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.grace.id
  tags = { Name = "grace-IGW" }
}

####################
# Subnets
####################
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.grace.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "grace-public-sub-${count.index}" }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.grace.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]
  tags = { Name = "grace-private-sub-${count.index}" }
}

####################
# Route Tables
####################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.grace.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

####################
# Security Group
####################
resource "aws_security_group" "grace" {
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

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "grace-sg" }
}

####################
# Launch Templates
####################
resource "aws_launch_template" "nginx" {
  name_prefix   = "nginx-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.grace.id]

  user_data = base64encode(<<EOF
#!/bin/bash
systemctl start nginx
EOF
)
}

resource "aws_launch_template" "app" {
  name_prefix   = "app-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.grace.id]
}

####################
# Auto Scaling Groups
####################
resource "aws_autoscaling_group" "nginx" {
  desired_capacity = 2
  max_size         = 2
  min_size         = 2
  vpc_zone_identifier = aws_subnet.public[*].id

  launch_template {
    id      = aws_launch_template.nginx.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_group" "app" {
  desired_capacity = 2
  max_size         = 2
  min_size         = 2
  vpc_zone_identifier = aws_subnet.private[*].id

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
}

####################
# Application Load Balancer
####################
resource "aws_lb" "nginx" {
  name               = "grace-nginx-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.grace.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "nginx" {
  name     = "nginx-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.grace.id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.nginx.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
}

resource "aws_autoscaling_attachment" "nginx" {
  autoscaling_group_name = aws_autoscaling_group.nginx.name
  lb_target_group_arn   = aws_lb_target_group.nginx.arn
}

####################
# Jenkins Server
####################
resource "aws_instance" "jenkins" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.grace.id]
  tags = { Name = "jenkins" }
}

####################
# PostgreSQL Server
####################
resource "aws_instance" "postgres" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.grace.id]
  tags = { Name = "postgres-db" }
}
    