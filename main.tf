
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

variable "ami_id" {
  description = "Ubuntu 24.04 AMI ID in Sydney"
  type        = string
  default     = "ami-01e91e94accc42eec"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "public-web-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "ap-southeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-web-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "public-web-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-web-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web" {
  name        = "public-web-sg"
  description = "Allow HTTP and restricted SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP web access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH is intentionally not opened to the internet.
  # Add a restricted SSH rule only if needed.

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public-web-sg"
  }
}

resource "aws_instance" "web" {
  ami                         = var.ami_id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -eux
    apt-get update
    apt-get install -y nginx
    cat > /var/www/html/index.html <<'HTML'
    <!doctype html>
    <html>
    <head><title>Terraform Web App</title></head>
    <body style="font-family:Arial;text-align:center;margin-top:100px">
      <h1>Hello from AWS EC2!</h1>
      <h2>Deployed using Terraform</h2>
      <p>VPC: public-web-vpc</p>
      <p>Availability Zone: ap-southeast-2a</p>
    </body>
    </html>
    HTML
    systemctl enable nginx
    systemctl restart nginx
  EOF

  tags = {
    Name = "terraform-public-web"
  }

  depends_on = [aws_route_table_association.public]
}

output "website_url" {
  description = "Open this URL in your browser"
  value       = "http://${aws_instance.web.public_ip}"
}

output "public_ip" {
  value = aws_instance.web.public_ip
}

output "vpc_id" {
  value = aws_vpc.main.id
}
root@ip-172-31-11-53:~/terraform-private-web#
