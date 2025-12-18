# DB Server 1 (Private Subnet AZ A)
resource "aws_instance" "db_1" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_1.id
  key_name               = "main" # Your Key Name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    Name = "db-server-1"
  }
}

# DB Server 2 (Private Subnet AZ B)
resource "aws_instance" "db_2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_2.id
  key_name               = "main" # Your Key Name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    Name = "db-server-2"
  }
}