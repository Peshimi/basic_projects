# Create two instances

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_key_pair" "kitty" {
	key_name = "kitty" 
	public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDExG0KQYae4ayrt5um+pjs1Pa/20HxlzEQv3T64ohk3vxHKk6Jo7gLWyRCDDLS2qjZLtsZE1iJz2RY5WU4x0AEMVhsLyKBqaPWhxtdSRRZrowGGNOrSof4EriHTvFVuWaN8XR02bZLyellT96ZvtQcuRnah77JOqaf6e/+Ys0dH9+lWRglYfPs8XI44iJRWLKC7Fm808sEd3XnmVXbBrymyyaa747Mbekemptr+EWm5OOU81d0/UgIxcQBvHwyynbUIJ/gD+0AfopaCTEG6AE6fc5jx6g7U02+rtM0RLwlBaXH5epuAF5Udgdr+XlvLorifSHnftleO3OAGSv8onBMn2+YycRV6zzJx6LFQ8E7I6EjPddQFealF6jKxxj+GYgV07GE9fk8Iquy9SmIyXSUtbZBGErT9LZUBea6P7IjyjnHNtgu9qMCWqVkNvCYQGZJD7qs3VISWct1FcX9RY557x8JowHp1rNIKUF79tvv/2kgqhofyHIE2iXW5or56xM= wojda@LAPTOP-U5E0HJM7"
}

resource "aws_instance" "public" {
	subnet_id = aws_subnet.main.id
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  security_groups      = [module.allow_ssh.security_group_id]
	key_name = "kitty"

  lifecycle {
    ignore_changes = [
      security_groups,
    ]
  }

  tags = {
    Name = "wordpress"
  }
}

resource "aws_instance" "private" {
	subnet_id = aws_subnet.main.id
  ami                    = data.aws_ami.ubuntu.id
  associate_public_ip_address = true
  instance_type          = "t3.micro"
  security_groups = [module.allow_ssh.security_group_id]
	key_name = "kitty"

  lifecycle {
    ignore_changes = [
      security_groups,
    ]
  }

  tags = {
    Name = "database"
  }
}

# Add security group with module

module "allow_ssh" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "allow_ssh"
  description = "Security group for user to allow SSH access"
  vpc_id      = aws_vpc.main.id

  ingress_cidr_blocks = ["10.0.1.0/16"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "ssh-access"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "http-access"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "https-access"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_cidr_blocks = [ "0.0.0.0/0" ] 
  egress_rules       = [ "all-all" ]
}
