# -----------------------------
# VPC
# -----------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "flask-app-vpc"
  }
}


# -----------------------------
# Public Subnet
# -----------------------------

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "flask-public-subnet"
  }
}
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "flask-public-subnet-b"
  }
}

# -----------------------------
# Internet Gateway
# -----------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "flask-app-igw"
  }
}


# -----------------------------
# Public Route Table
# -----------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "flask-public-route-table"
  }
}


# -----------------------------
# Route Table Association
# -----------------------------

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


# -----------------------------
# Security Group
# -----------------------------

resource "aws_security_group" "app" {
  name        = "flask-app-sg"
  description = "Security group for Flask application"
  vpc_id      = aws_vpc.main.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Flask testing
  ingress {
    description = "Flask"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "flask-app-sg"
  }
}


# -----------------------------
# EC2 Instance
# -----------------------------

resource "aws_instance" "app" {
  ami           = "ami-0f918f7e67a3323f0"
  instance_type = "t3.micro"

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = true

  key_name = "linux"

  tags = {
    Name = "flask-application-server"
  }
}
# -----------------------------
# RDS MySQL Security Group
# -----------------------------

resource "aws_security_group" "rds" {
  name        = "flask-rds-sg"
  description = "Allow MySQL access from Flask EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from Flask EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "flask-rds-sg"
  }
}

# -----------------------------
# RDS MySQL
# -----------------------------

resource "aws_db_instance" "mysql" {
  identifier           = "flask-employee-db"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"

  allocated_storage    = 20
  storage_type         = "gp3"

  db_name              = "employee_db"
  username             = "admin"
  password             = "var.db_password"

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.mysql.name

  publicly_accessible    = true
  skip_final_snapshot    = true
  backup_retention_period = 0

  tags = {
    Name = "flask-employee-mysql"
  }
}

resource "aws_db_subnet_group" "mysql" {
  name = "flask-mysql-subnet-group"

  subnet_ids = [
    aws_subnet.public.id,
    aws_subnet.public_b.id
  ]

  tags = {
    Name = "flask-mysql-subnet-group"
  }
}
