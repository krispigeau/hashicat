terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.63.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Create a new VPC block
resource "aws_vpc" "lab" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "vpc-${var.prefix}" }
}

# Create internet gateway
resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "igw-${var.prefix}" }
}

# Create Public Route Table
resource "aws_route_table" "lab" {
  vpc_id = aws_vpc.lab.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab.id
  }
  tags = { Name = "ex_public_rt" }
}

resource "aws_subnet" "lab-public" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.prefix}-SN-public" }
}

# Associate the subnet and the route table
resource "aws_route_table_association" "public-access" {
  subnet_id      = aws_subnet.lab-public.id
  route_table_id = aws_route_table.lab.id
}

resource "aws_security_group" "webserver-SG" {
  name        = "webserver-SG"
  description = "allow SSH and HTTP"
  vpc_id      = aws_vpc.lab.id
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow Everything"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Deploy an EC2 instace
resource "aws_instance" "EC2" {
  count = 2
  ami             = "ami-006dcf34c09e50022"
  instance_type   = "t2.micro"
  key_name        = "kris_desktop"
  subnet_id       = aws_subnet.lab-public.id
  security_groups = [aws_security_group.webserver-SG.id]
  user_data       = <<-EOF
                #!/bin/bash
                yum install httpd -y
                systemctl restart httpd
                systemctl enable httpd
                echo "<html><body> \
                <img src='http://${var.placeholder}/${var.width}/${var.height}'></img> \
                <h2>'Meow World!'</h2> \
                <body> \
                'Welcome to ${var.environment}'s app. Replace this text with your own.' \
                </body> \
                </html>" > /var/www/html/index.html
                EOF
  tags            = { Name = "EC2-${var.prefix}-${count.index}" }
}


output "web-address" {
  value = aws_instance.EC2.public_dns
}
