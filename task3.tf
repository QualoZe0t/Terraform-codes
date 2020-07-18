provider "aws" {
  region                  = "ap-south-1"
  profile                 = "akhil"
}
# KEY PAIR
resource "tls_private_key" "keypair" {
  algorithm   = "RSA"
}
resource "local_file" "privatekey" {
    content     = tls_private_key.keypair.private_key_pem
    filename = "key1.pem"
}
resource "aws_key_pair" "deployer" {
  key_name   = "key1.pem"
  public_key = tls_private_key.keypair.public_key_openssh
}
# VPC
resource "aws_vpc" "vpc" {
    cidr_block       = "192.168.0.0/16"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    instance_tenancy = "default"

  tags = {
    Name = "vpc-task"
  }
}
# PUBLIC SUBNET
resource "aws_subnet" "pubsub" {
  vpc_id     =  aws_vpc.vpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-task"
  }
}
# PRIVATE SUBNET
resource "aws_subnet" "prisub" {
  vpc_id     =  aws_vpc.vpc.id
  cidr_block = "192.168.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "private-subnet"
  }
}
# INTERNET GATEWAY
resource "aws_internet_gateway" "intgw" {
  vpc_id =  aws_vpc.vpc.id
  tags = {
    Name = "int-gateway"
  }
}
# ROUTING TABLE
resource "aws_route_table" "route-table" {
  vpc_id =  aws_vpc.vpc.id
  
  tags = {
    Name = "route-table"
  }
}
resource "aws_route" "rt" {
  route_table_id            = aws_route_table.route-table.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id =  aws_internet_gateway.intgw.id
  
}
resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.route-table.id
}
# SECURITY GROUP FOR WORDPRESS
resource "aws_security_group" "wpsg" {
  name        = "wordpress"
  description = "Allow TLS inbound traffic"
  vpc_id      =   aws_vpc.vpc.id

  ingress {
    description = "ssh"
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http"
    from_port   = 0
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
    Name = "wordpress"
  }
}

# SECURITY GROUP FOR MYSQL
resource "aws_security_group" "mysqlsg" {
  name        = "mysql"
  description = "Allow MYSQL"
  vpc_id      =   aws_vpc.vpc.id

  ingress {
    description = "MYSQL/Aurora"
    from_port   = 0
    to_port     = 3306
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
    Name = "mysql"
  }
}
# WORDPRESS INSTANCE
resource "aws_instance" "wp" {
  ami             = "ami-000cbce3e1b899ebd"
  instance_type   = "t2.micro"
  key_name        = "key1.pem"
  security_groups =  [  aws_security_group.wpsg.id  ]
  subnet_id       =  aws_subnet.pubsub.id
  
  tags = {
    Name = "wordpress-ins"
  }
}
# MYSQL INSTANCE
resource "aws_instance" "mysql" {
  ami             = "ami-08706cb5f68222d09"
  instance_type   = "t2.micro"
  key_name        = "key1.pem"
  security_groups =  [  aws_security_group.mysqlsg.id  ]
  subnet_id =  aws_subnet.prisub.id

  tags = {
    Name = "mysql-ins"
  }
}