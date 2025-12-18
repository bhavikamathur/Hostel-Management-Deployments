# Security group for ALB
# resource "aws_security_group" "alb_sg" {
#   name        = "${var.project}-alb-sg"
#   description = "Allow HTTP to ALB"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = { Name = "${var.project}-alb-sg" }
# }

# # ALB
# resource "aws_lb" "alb" {
#   name               = "${var.project}-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.alb_sg.id]
#   subnets            = [for s in aws_subnet.public : s.id]
#   tags               = { Name = "${var.project}-alb" }
# }

# Target Group
# resource "aws_lb_target_group" "tg" {
#   name     = "${var.project}-tg"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.main.id
#   health_check {
#     path                = "/"
#     protocol            = "HTTP"
#     matcher             = "200-399"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#   }
#   tags = { Name = "${var.project}-tg" }
# }

# Target Group


# Register instances as targets
# resource "aws_lb_target_group_attachment" "targets" {
#   for_each         = aws_instance.web
#   target_group_arn = aws_lb_target_group.tg.arn
#   target_id        = each.value.id
#   port             = 5000
# }


# # Listener on port 80
# resource "aws_lb_listener" "http" {
#   load_balancer_arn = aws_lb.alb.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.tg.arn
#   }
# }


# ------------------------------------------------------
# Security Group for ALB
# ------------------------------------------------------
resource "aws_security_group" "alb_sg" {
  name        = "${var.project}-alb-sg"
  description = "Allow HTTP to ALB"
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

  tags = {
    Name = "${var.project}-alb-sg"
  }
}

# ------------------------------------------------------
# Application Load Balancer
# ------------------------------------------------------
resource "aws_lb" "alb" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for s in aws_subnet.public : s.id]

  tags = {
    Name = "${var.project}-alb"
  }
}

# ------------------------------------------------------
# Target Group (Corrected for port 5000)
# ------------------------------------------------------
resource "aws_lb_target_group" "tg" {
  name     = "${var.project}-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    path                = "/"
    port                = "5000"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project}-tg"
  }
}

# ------------------------------------------------------
# Register EC2 Instances to Target Group
# ------------------------------------------------------
resource "aws_lb_target_group_attachment" "targets" {
  for_each         = aws_instance.web
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = each.value.id
  port             = 5000
}

# ------------------------------------------------------
# ALB Listener (Port 80 → Forward to TG on 5000)
# ------------------------------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}