# VPC
resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
}

# Public Subnets for Web Tier
resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.public_subnet1_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.public_subnet2_cidr
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

# Private Subnets for Logic Tier
resource "aws_subnet" "private_sub1" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = var.private_subnet1_cidr
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private_sub2" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = var.private_subnet2_cidr
  availability_zone = "us-east-1b"
}

# Private Subnets for Data Tier (Database)
resource "aws_subnet" "db_sub1" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = var.db_subnet1_cidr
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "db_sub2" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = var.db_subnet2_cidr
  availability_zone = "us-east-1b"
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}

# Route Table and Association for Public Subnets
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.RT.id
}

# Security Groups
resource "aws_security_group" "webSg" {
  name   = "web"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name = "Web-sg"
  }
}

resource "aws_security_group" "appSg" {
  name   = "app"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "HTTP from Web Tier"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.private_sub1.cidr_block, aws_subnet.private_sub2.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "App-sg"
  }
}

resource "aws_security_group" "dbSg" {
  name   = "db"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "MySQL from App Tier"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.db_sub1.cidr_block, aws_subnet.db_sub2.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DB-sg"
  }
}

# Application Load Balancer (ALB)
resource "aws_lb" "myalb" {
  name               = "myalb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.webSg.id]
  subnets         = [aws_subnet.sub1.id, aws_subnet.sub2.id]

  tags = {
    Name = "web"
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "myTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver2.id
  port             = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}

# EC2 Instances - Web Tier
resource "aws_instance" "webserver1" {
  ami                    = "ami-0261755bbcb8c4a84"
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id              = aws_subnet.sub1.id
  user_data              = base64encode(file("userdata/web_userdata.sh"))
}

resource "aws_instance" "webserver2" {
  ami                    = "ami-0261755bbcb8c4a84"
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id              = aws_subnet.sub2.id
  user_data              = base64encode(file("userdata/web_userdata.sh"))
}

# EC2 Instances - Logic Tier
resource "aws_instance" "appserver1" {
  ami                    = "ami-0261755bbcb8c4a84"
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.appSg.id]
  subnet_id              = aws_subnet.private_sub1.id
  user_data              = base64encode(file("userdata/app_userdata.sh"))
}

resource "aws_instance" "appserver2" {
  ami                    = "ami-0261755bbcb8c4a84"
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.appSg.id]
  subnet_id              = aws_subnet.private_sub2.id
  user_data              = base64encode(file("userdata/app_userdata.sh"))
}

# RDS Instance - Data Tier
resource "aws_db_subnet_group" "mydb_subnet_group" {
  name       = "mydb-subnet-group"
  subnet_ids = [aws_subnet.db_sub1.id, aws_subnet.db_sub2.id]

  tags = {
    Name = "mydb-subnet-group"
  }
}

resource "aws_db_instance" "mydb" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.db_instance_class
  name                 = "mydb"
  username             = "admin"
  password             = "password"
  vpc_security_group_ids = [aws_security_group.dbSg.id]
  db_subnet_group_name = aws_db_subnet_group.mydb_subnet_group.name
  skip_final_snapshot  = true
}
