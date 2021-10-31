terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

# Create an instance
#data "aws_ami" "ubuntu" { 
#most_recent = true
#
#  filter {
#    name   = "name"
#    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
#  }
#
#  filter {
#    name   = "virtualization-type"
#    values = ["hvm"]
#  }
#
#  owners = ["099720109477"]
#}
#
#resource "aws_instance" "web" {
#  ami           = data.aws_ami.ubuntu.id
#  instance_type = "t3.micro"
#
#  tags = {
#    Name = "Wordpress"
#  }
#}

# EIP 
resource "aws_eip" "foo" {
  vpc = true
}

# Internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

# Public NAT 
resource "aws_nat_gateway" "sth" {
  allocation_id = aws_eip.foo.id
  subnet_id     = aws_subnet.main.id

  tags = {
    Name = "gw NAT"
  }

  depends_on = [aws_internet_gateway.gw]
}

# Subnet
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
	availability_zone = "us-east-1a"

  tags = {
    Name = "Main"
  }
}

# Route table
resource "aws_route_table" "default" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "fall"
  }
}

resource "aws_route" "main_to_internet" {
  route_table_id         = aws_route_table.default.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public" {
	subnet_id = aws_subnet.main.id
	route_table_id = aws_route_table.default.id
}
