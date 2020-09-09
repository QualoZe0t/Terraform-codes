variable "rdspasswd" {}
variable "rdsusername" {}
provider "aws" {
  region                  = "ap-south-1"
  profile                 = "akhil"
}
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_security_group" "sg" {
  name        = "db-wizard"
  description = "Allow Database inbound traffic"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description = "MYSQL/Aurora"
    from_port   = 3306
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
    Name = "sg-for-db"
  }
}  

resource "aws_db_instance" "default" {
  identifier           = "wpdatabase"
  engine               = "mysql"
  engine_version       = "5.7.21"
  name                 = "poddb"
  username             = var.rdsusername
  password             = var.rdspasswd
  allocated_storage    = 20
  max_allocated_storage = 25
  storage_type         = "gp2"
  availability_zone    = "ap-south-1b"
  instance_class       = "db.t2.micro"
  port                 = 3306
  publicly_accessible  = true
  skip_final_snapshot = true
  vpc_security_group_ids = [ "${aws_security_group.sg.id}" ]
  tags = {
    Name = "task6-awsrds"
  }
    depends_on = [
    aws_security_group.sg,
  ]
  }
output "rds_dbhost" {
    value = aws_db_instance.default.endpoint
}
output "rds_dbname" {
    value = aws_db_instance.default.name
}
