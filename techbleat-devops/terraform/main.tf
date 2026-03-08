# -----------------------------------------------------------------------------
# Techbleat Superstore - Infrastructure as Code
# EC2 + Security Group + RDS + VPC + Route53 (optional)
# -----------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# -----------------------------------------------------------------------------
# VPC & Networking (per diagram: 10.0.0.0/16)
# -----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "techbleat-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "techbleat-igw"
  }
}

# Public Subnets - Web App Tier (10.0.1.0/24, 10.0.2.0/24)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block               = "10.0.1.0/24"
  availability_zone        = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch  = true

  tags = {
    Name = "techbleat-public-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block               = "10.0.2.0/24"
  availability_zone        = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch  = true

  tags = {
    Name = "techbleat-public-2"
  }
}

# Private Subnets - Application Tier & DB Tier (10.0.3.0/24, 10.0.4.0/24)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "techbleat-private-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "techbleat-private-2"
  }
}

# Route table - Public subnets -> Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "techbleat-public-rt"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# -----------------------------------------------------------------------------
# Security Group - Ports 22, 80, 443 only (8000 NOT public) - Web App Tier
# -----------------------------------------------------------------------------
resource "aws_security_group" "techbleat_sg" {
  name        = "techbleat-security-group"
  description = "Web App Tier - SSH, HTTP, HTTPS only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP - Lets Encrypt validation"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS - Public traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "techbleat-sg"
  }
}

# -----------------------------------------------------------------------------
# RDS Security Group - PostgreSQL from EC2 only
# -----------------------------------------------------------------------------
resource "aws_security_group" "rds_sg" {
  name        = "techbleat-rds-sg"
  description = "DB Tier - PostgreSQL from Web/App tier only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.techbleat_sg.id]
    description     = "PostgreSQL from EC2"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "techbleat-rds-sg"
  }
}

# -----------------------------------------------------------------------------
# DB Subnet Group (RDS requires 2+ subnets in different AZs)
# -----------------------------------------------------------------------------
resource "aws_db_subnet_group" "techbleat" {
  name       = "techbleat-db-subnet"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "techbleat-db-subnet"
  }
}

# -----------------------------------------------------------------------------
# RDS PostgreSQL Instance
# -----------------------------------------------------------------------------
resource "aws_db_instance" "techbleat_db" {
  identifier     = "techbleat-db"
  engine         = "postgres"
  engine_version = "15.12"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.techbleat.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false

  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  tags = {
    Name = "techbleat-db"
  }
}

# -----------------------------------------------------------------------------
# EC2 Instance (App Server)
# -----------------------------------------------------------------------------
resource "aws_instance" "techbleat_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.techbleat_sg.id]

  associate_public_ip_address = true
  key_name                   = var.key_name

  tags = {
    Name = "techbleat-superstore"
  }
}

# -----------------------------------------------------------------------------
# Route53 DNS (fully automated - create zone + A record when domain_name set)
# -----------------------------------------------------------------------------
locals {
  root_domain = var.domain_name != "" ? join(".", slice(split(".", var.domain_name), 1, length(split(".", var.domain_name)))) : ""
  create_zone = var.domain_name != "" && var.route53_zone_id == ""
  zone_id     = local.create_zone ? aws_route53_zone.main[0].zone_id : var.route53_zone_id
}

resource "aws_route53_zone" "main" {
  count   = local.create_zone ? 1 : 0
  name    = local.root_domain
  comment = "Techbleat Superstore - created by Terraform"

  tags = {
    Name = "techbleat-zone"
  }
}

resource "aws_route53_record" "app" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = local.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [aws_instance.techbleat_server.public_ip]
}
