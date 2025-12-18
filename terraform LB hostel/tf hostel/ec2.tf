# Security Group for EC2
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project}-ec2-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # ALB SG will be allowed explicitly; for simplicity we'll allow HTTP from anywhere too
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Flask App Traffic from ALB"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from anywhere (change for production)"
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

  tags = { Name = "${var.project}-ec2-sg" }
}


data "template_file" "user_data" {
  template = <<-EOT
    #!/bin/bash
    yum update -y

    # Install Docker
    amazon-linux-extras install docker -y
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ec2-user

    # Install Docker Compose v2
    mkdir -p /usr/libexec/docker/cli-plugins
    curl -SL https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-linux-x86_64 \
      -o /usr/libexec/docker/cli-plugins/docker-compose
    chmod +x /usr/libexec/docker/cli-plugins/docker-compose

    # Create docker-compose file
    mkdir /app
    cat <<EOF > /app/docker-compose.yml
version: '3.8'

services:
  web:
    image: bipingupta051/hostel-management-2tier-web:latest
    # image : rohithubstore/final_flask:latest
    container_name: hostel-web
    restart: always
    environment:
      DB_HOST: ${aws_db_instance.mysql.address}
      DB_PORT: 3306
      DB_NAME: hostel_db
      DB_USER: admin
      DB_PASSWORD: admin123
    ports:
      - "5000:5000"

EOF

    cd /app 
    docker compose up -d
  EOT
}

#     # Install Docker
#     amazon-linux-extras install docker -y
#     systemctl enable docker
#     systemctl start docker
#     usermod -aG docker ec2-user

#     # Install Docker Compose v2
#     mkdir -p /usr/libexec/docker/cli-plugins
#     curl -SL https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-linux-x86_64 \
#       -o /usr/libexec/docker/cli-plugins/docker-compose
#     chmod +x /usr/libexec/docker/cli-plugins/docker-compose

#     # Create docker-compose file
#     mkdir /app
#     cat <<EOF > /app/docker-compose.yml
# version: '3.8'

# services:
#   db:
#     image: mariadb:10.6
#     container_name: hostel-db
#     restart: always
#     environment:
#       MYSQL_ROOT_PASSWORD: admin@123
#       MYSQL_DATABASE: hostel_db
#       MYSQL_ROOT_HOST: "%"
#     volumes:
#       - db_data:/var/lib/mysql

#   web:
#     image: bipingupta051/hostel-management-2tier-web:latest
#     container_name: hostel-web
#     restart: always
#     depends_on:
#       - db
#     environment:
#       DB_HOST: db
#       DB_PORT: 3306
#       DB_NAME: hostel_db
#       DB_USER: root
#       DB_PASSWORD: admin@123
#     ports:
#       - "5000:5000"

# volumes:
#   db_data:
# EOF

#     cd /app
#     docker compose up -d
#   EOT
# }



# AMI: Amazon Linux 2 (use data lookup)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Create two EC2 instances (one per public subnet)
resource "aws_instance" "web" {
  for_each                    = aws_subnet.public
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = each.value.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  user_data                   = data.template_file.user_data.rendered
  key_name                    = var.key_name != "" ? var.key_name : null

  tags = {
    Name = "${var.project}-web-${each.key}"
  }
}