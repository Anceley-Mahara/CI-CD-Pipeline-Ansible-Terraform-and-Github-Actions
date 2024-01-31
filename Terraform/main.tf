provider "aws" {
  region = "eu-west-1"
}

# Create a VPC
resource "aws_vpc" "assessment_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "assessment_vpc"
  }
}

# Create two public subnets in two availability zones
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.assessment_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.assessment_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet2"
  }
}

# Create Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "assessment_igw" {
  vpc_id = aws_vpc.assessment_vpc.id

  tags = {
    Name = "assessment_igw"
  }
}

# Attach the Internet Gateway to the public subnets
resource "aws_route_table" "public_route_table_1" {
  vpc_id = aws_vpc.assessment_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.assessment_igw.id
  }

  tags = {
    Name = "PublicRouteTable1"
  }
}

resource "aws_route_table" "public_route_table_2" {
  vpc_id = aws_vpc.assessment_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.assessment_igw.id
  }

  tags = {
    Name = "PublicRouteTable2"
  }
}

# Create security group for EC2 Instance 1
resource "aws_security_group" "instance_1_sg" {
  name        = "instance_1_sg"
  description = "Security group for EC2 Instance 1"
  vpc_id      = aws_vpc.assessment_vpc.id

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

  tags = {
    Name = "Instance1SecurityGroup"
  }
}

# Create security group for EC2 Instance 2
resource "aws_security_group" "instance_2_sg" {
  name        = "instance_2_sg"
  description = "Security group for EC2 Instance 2"
  vpc_id      = aws_vpc.assessment_vpc.id

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

  tags = {
    Name = "Instance2SecurityGroup"
  }
}

# Create EC2 Instances
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "instance_1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet_1.id
  key_name      = "xxxxxx" # replace with your key pair name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.instance_1_sg.id]         
            
  tags = {
    Name = "server1-chat-docker-app"
  }
}

resource "aws_instance" "instance_2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet_2.id
  key_name      = "xxxxxxx"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.instance_2_sg.id] 
              
  tags = {
    Name = "server2-nginx"
  }
}

# Output the public IP addresses of the instances
output "public_ip_instance_1" {
  value = aws_instance.instance_1.public_ip
}

output "public_ip_instance_2" {
  value = aws_instance.instance_2.public_ip
}
