# Get Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# Web Server 1
resource "aws_instance" "web_server_1" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  key_name                    = "main"                
  subnet_id                   = aws_subnet.public_1.id
  associate_public_ip_address = true                  
  vpc_security_group_ids      = [aws_security_group.web_sg.id]

  tags = {
    Name = "web-server-1"
    Role = "web"
  }
}

# Web Server 2
resource "aws_instance" "web_server_2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  key_name                    = "main"
  subnet_id                   = aws_subnet.public_2.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web_sg.id]

  tags = {
    Name = "web-server-2"
    Role = "web"
  }
}

# OPTIONAL: Discover running web instances by Role tag
data "aws_instances" "web" {
  instance_tags = {
    Role = "web"
  }
  instance_state_names = ["running"]
}

# OPTIONAL: Pull details (IPs, tags) for each discovered instance
data "aws_instance" "web" {
  for_each    = toset(data.aws_instances.web.ids)
  instance_id = each.value
}