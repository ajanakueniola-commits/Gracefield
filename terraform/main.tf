provider "aws" {
  region = var.region
}

####################
# AMI Lookup
####################
data "aws_ami" "packer_or_amazon" {
  most_recent = true
  owners      = var.packer_ami_owner != "" ? [var.packer_ami_owner] : ["amazon"]

  filter {
    name   = "name"
    values = var.packer_ami_name_pattern != "" ? [var.packer_ami_name_pattern] : ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

####################
# VPC
####################
resource "aws_vpc" "grace" {
  cidr_block = var.vpc_cidr
  tags       = { Name = "grace-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.grace.id
  tags   = { Name = "grace-IGW" }
}

####################
# Subnets
####################
resource "aws_subnet" "public" {
  count                   = 1
  vpc_id                  = aws_vpc.grace.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "grace-public-sub-${count.index}" }
}

resource "aws_subnet" "private" {
  count             = 1
  vpc_id            = aws_vpc.grace.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]
  tags = { Name = "grace-private-sub-${count.index}" }
}

resource "aws_subnet" "grace_private" {
  count             = 1
  vpc_id            = aws_vpc.grace-vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "grace-private-sub-${count.index}"
  }
}


####################
# Route Table
####################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.grace.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = 1
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

####################
# Security Groups
####################
resource "aws_security_group" "grace" {
  vpc_id = aws_vpc.grace.id
  name   = "grace-sg"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL (private access only)
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
# NGINX Instances (Public)
####################
resource "aws_instance" "nginx" {
  count                       = 1
  ami                         = var.ami_id != "" ? var.ami_id : data.aws_ami.packer_or_amazon.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[count.index].id
  vpc_security_group_ids      = [aws_security_group.grace.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install -y nginx1
    systemctl enable nginx
    systemctl start nginx
    echo "Hello from nginx instance ${count.index}" > /usr/share/nginx/html/index.html
  EOF

  tags = { Name = "nginx-${count.index}" }
}

####################
# App Instances (Private)
####################
resource "aws_instance" "app" {
  count                  = 1
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.packer_or_amazon.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private[count.index].id
  vpc_security_group_ids = [aws_security_group.grace.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install -y python3
    python3 -m venv /opt/venv
    source /opt/venv/bin/activate
    pip install flask
  EOF

  tags = { Name = "app-${count.index}" }
}

####################
# Jenkins Instance (Public)
####################
# resource "aws_instance" "jenkins" {
#   ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.packer_or_amazon.id
#   instance_type          = var.instance_type
#   subnet_id              = aws_subnet.public[0].id
#   vpc_security_group_ids = [aws_security_group.grace.id]

#   user_data = <<-EOF
#     #!/bin/bash
#     yum update -y
#     sudo yum install java-17-amazon-corretto -y
# sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
# sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
# sudo yum install jenkins -y
# sudo systemctl enable jenkins
# sudo systemctl start jenkins
# sudo yum install -y yum-utils shadow-utils
# sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
# sudo yum install packer -y
# sudo yum install -y yum-utils shadow-utils
# sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
# sudo yum install terraform -y
#   EOF

#   tags = { Name = "jenkins" }
# }

####################
# PostgreSQL Instance (Private)
####################
# resource "aws_instance" "postgres" {
#   ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.packer_or_amazon.id
#   instance_type          = var.instance_type
#   subnet_id              = aws_subnet.private[0].id
#   vpc_security_group_ids = [aws_security_group.grace.id]

#   user_data = <<-EOF
#     #!/bin/bash
#     yum update -y
#     amazon-linux-extras install -y postgresql13
#     systemctl enable postgresql
#     systemctl start postgresql
#   EOF

#   tags = { Name = "postgres-db" }
# }

resource "aws_db_instance" "postgres" {
  identifier = "production-postgres"

  engine         = "postgres"
  engine_version = "14.19"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_encrypted = false

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.grace.name
  vpc_security_group_ids = [aws_security_group.db.id]

  backup_retention_period = 0
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = false

  tags = {
    Name = "PostgreSQL"
  }
}
resource "aws_db_subnet_group" "grace" {
  name       = "grace-db-subnet-group"
  subnet_ids = aws_db_subnet.private[*].id

  tags = {
    Name = "grace-db-subnet-group"
  }
}

resource "aws_security_group" "db" {
  vpc_id = aws_vpc.grace.id
  name   = "grace-db-sg"

  # PostgreSQL access from within VPC
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
}