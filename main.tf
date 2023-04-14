# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


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
resource "aws_vpc" "vpc-practice" {
  cidr_block           = "142.55.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "vpc-practice" }
}

# Create internet gateway
resource "aws_internet_gateway" "igw-example" {
  vpc_id = aws_vpc.vpc-practice.id
  tags   = { Name = "igw-example" }
}

# Create Public Route Table
resource "aws_route_table" "public-practice-RT" {
  vpc_id = aws_vpc.vpc-practice.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-example.id
  }
  tags = { Name = "ex_public_rt" }
}

resource "aws_subnet" "public-example-subnet" {
  vpc_id                  = aws_vpc.vpc-practice.id
  cidr_block              = "142.55.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "example-SN-public" }
}

# Associate the subnet and the route table
resource "aws_route_table_association" "public-access" {
  subnet_id      = aws_subnet.public-example-subnet.id
  route_table_id = aws_route_table.public-practice-RT.id
}

resource "aws_security_group" "webserver-SG" {
  name        = "webserver-SG"
  description = "allow SSH and HTTP"
  vpc_id      = aws_vpc.vpc-practice.id
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
  ami             = "ami-006dcf34c09e50022"
  instance_type   = "t2.micro"
  key_name        = "kris_desktop"
  subnet_id       = aws_subnet.public-example-subnet.id
  security_groups = [aws_security_group.webserver-SG.id]
  user_data       = <<-EOF
                #!/bin/bash
                yum install httpd -y
                systemctl restart httpd
                systemctl enable httpd
                yum install docker -y
                usermod -aG docker ec2-user_data
                systemctl restart docker
                docker run -itd -p 27017:27017 mongo
                EOF
  tags            = { Name = "Ec2-terraformed" }
}


output "web-address" {
  value = aws_instance.EC2.public_dns
}
