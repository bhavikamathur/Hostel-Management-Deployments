#############################################
# RDS SUBNET GROUP (private Subnets)
#############################################

resource "aws_db_subnet_group" "db_subnets" {
  name       = "${var.project}-db-subnet-group"
  subnet_ids = [for s in aws_subnet.public : s.id]


  tags = {
    Name = "${var.project}-db-subnet-group"
  }
}

#############################################
# RDS SECURITY GROUP
#############################################

resource "aws_security_group" "db_sg" {
  name        = "${var.project}-db-sg"
  description = "Allow EC2 instances to access RDS MySQL"
  vpc_id      = aws_vpc.main.id

  # Allow EC2 → RDS access (port 3306)
  ingress {
    description     = "MySQL from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  # Allow RDS to access internet for updates
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-db-sg"
  }
}

#############################################
# RDS MYSQL INSTANCE
#############################################

resource "aws_db_instance" "mysql" {
  identifier             = "${var.project}-mysql"
  allocated_storage      = 20
  storage_type           = "gp2"

  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"

  db_name                = "hostel_db"
  username               = "admin"
  password               = "admin123"

  publicly_accessible    = false
  multi_az               = false
  skip_final_snapshot    = true

  port                   = 3306
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name

  tags = {
    Name = "${var.project}-mysql"
  }
}

#############################################
# OUTPUT (For debugging / EC2 env)
#############################################

