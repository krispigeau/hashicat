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

# Make three subnets, each in a different AZ
resource "aws_subnet" "lab-public-0" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.prefix}-SN-public-0" }
}

resource "aws_subnet" "lab-public-1" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.prefix}-SN-public-1" }
}

resource "aws_subnet" "lab-public-2" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.prefix}-SN-public-2" }
}

# Associate the subnets with the public route table
resource "aws_route_table_association" "public-access-0" {
  subnet_id      = aws_subnet.lab-public-0.id
  route_table_id = aws_route_table.lab.id
}

resource "aws_route_table_association" "public-access-1" {
  subnet_id      = aws_subnet.lab-public-1.id
  route_table_id = aws_route_table.lab.id
}

resource "aws_route_table_association" "public-access-2" {
  subnet_id      = aws_subnet.lab-public-2.id
  route_table_id = aws_route_table.lab.id
}

# Make a security group
resource "aws_security_group" "lab" {
  name        = "${var.prefix}-SG"
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
resource "aws_instance" "EC2-0" {
  ami             = "ami-006dcf34c09e50022"
  instance_type   = "t2.micro"
  key_name        = "kris_desktop"
  subnet_id       = aws_subnet.lab-public-0.id
  security_groups = [aws_security_group.lab.id]
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
  tags            = { Name = "EC2-${var.prefix}-0" }
}

resource "aws_instance" "EC2-1" {
  ami             = "ami-006dcf34c09e50022"
  instance_type   = "t2.micro"
  key_name        = "kris_desktop"
  subnet_id       = aws_subnet.lab-public-1.id
  security_groups = [aws_security_group.lab.id]
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
  tags            = { Name = "EC2-${var.prefix}-1" }
}

resource "aws_instance" "EC2-2" {
  ami             = "ami-006dcf34c09e50022"
  instance_type   = "t2.micro"
  key_name        = "kris_desktop"
  subnet_id       = aws_subnet.lab-public-2.id
  security_groups = [aws_security_group.lab.id]
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
  tags            = { Name = "EC2-${var.prefix}-2" }
}


# Create Target Group

resource "aws_lb_target_group" "lab" {
  name     = "${var.prefix}-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.lab.id
}

resource "aws_lb_target_group_attachment" "lab-0" {
  target_group_arn = aws_lb_target_group.lab.arn
  target_id        = aws_instance.EC2-0.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "lab-1" {
  target_group_arn = aws_lb_target_group.lab.arn
  target_id        = aws_instance.EC2-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "lab-2" {
  target_group_arn = aws_lb_target_group.lab.arn
  target_id        = aws_instance.EC2-2.id
  port             = 80
}


resource "aws_s3_bucket" "lab" {
  bucket = "my-tf-test-bucket-kpasdass8838s8dfsd8f93sdf"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_lb" "alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lab.id]

  subnets = [
    aws_subnet.lab-public-0.id,
    aws_subnet.lab-public-1.id,
  ]

  tags = {
    Environment = "dev"
  }
}

resource "aws_lb_listener" "alb_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.alb_target_group.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "alb_target_group" {
  name_prefix = "my-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.lab.id
  health_check {
    path = "/"
  }

  tags = {
    Environment = "dev"
  }
}