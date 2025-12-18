# Discover AZs; use 4
data "aws_availability_zones" "available" {
  state = "available"
}

# Amazon Linux 2023 AMI via SSM parameter
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 4)
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(var.tags, { Name = "hostel-vpc" })
}

# IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "hostel-igw" })
}

# Public subnets in AZ[0], AZ[1]
resource "aws_subnet" "public" {
  for_each = {
    for idx, cidr in var.public_subnet_cidrs :
    idx => {
      cidr = cidr
      az   = local.azs[idx]
    }
  }
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name = "hostel-public-${each.key}"
    Tier = "public"
  })
}

# Private subnets in AZ[2], AZ[3]
resource "aws_subnet" "private" {
  for_each = {
    for idx, cidr in var.private_subnet_cidrs :
    idx => {
      cidr = cidr
      az   = local.azs[idx + 2]
    }
  }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = merge(var.tags, {
    Name = "hostel-private-${each.key}"
    Tier = "private"
  })
}

# NAT: EIP + NAT in public[0]
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(var.tags, { Name = "hostel-nat-eip" })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["0"].id
  tags          = merge(var.tags, { Name = "hostel-nat" })
  depends_on    = [aws_internet_gateway.igw]
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "hostel-rt-public" })
}

resource "aws_route" "public_inet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "hostel-rt-private" })
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# Security groups
resource "aws_security_group" "alb_sg" {
  name        = "hostel-alb-sg"
  description = "ALB SG"
  vpc_id      = aws_vpc.main.id

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

  tags = merge(var.tags, { Name = "hostel-alb-sg" })
}

resource "aws_security_group" "web_sg" {
  name        = "hostel-web-sg"
  description = "Web servers SG"
  vpc_id      = aws_vpc.main.id

  # ALB -> Web :5000
  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "ALB to Web :5000"
  }

  # SSH from your IP (admin)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
    description = "SSH from admin"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "hostel-web-sg" })
}

resource "aws_security_group" "db_sg" {
  name        = "hostel-db-sg"
  description = "DB servers SG"
  vpc_id      = aws_vpc.main.id

  # MySQL from web SG
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
    description     = "Web to DB :3306"
  }

  # SSH from web SG (for ProxyJump)
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
    description     = "SSH via bastion (web SG)"
  }

  # Optional: SSH direct from your IP (if you ever need it)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
    description = "SSH from admin (optional)"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "hostel-db-sg" })
}

# Web instances across public[0], public[1]
resource "aws_instance" "web" {
  count         = 2
  ami           = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.web_instance_type
  subnet_id     = aws_subnet.public[tostring(count.index)].id

  associate_public_ip_address = true
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.web_sg.id]

  tags = merge(var.tags, {
    Name = "hostel-web-${count.index}"
    Role = "web"
  })
}

# DB instances across private[0], private[1]
resource "aws_instance" "db" {
  count         = 2
  ami           = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.db_instance_type
  subnet_id     = aws_subnet.private[tostring(count.index)].id

  associate_public_ip_address = false
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.db_sg.id]

  tags = merge(var.tags, {
    Name = "hostel-db-${count.index}"
    Role = "db"
  })
}

# ALB in both public subnets
resource "aws_lb" "alb" {
  name               = "hostel-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for s in aws_subnet.public : s.id]
  tags               = merge(var.tags, { Name = "hostel-alb" })
}

resource "aws_lb_target_group" "tg" {
  name     = "hostel-web-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, { Name = "hostel-web-tg" })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Register web instances
resource "aws_lb_target_group_attachment" "web_attach" {
  count            = 2
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web[count.index].id
  port             = 5000
}

