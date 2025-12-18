# 1. Application Load Balancer
resource "aws_lb" "main" {
  name               = "hostel-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

# 2. Target Group
resource "aws_lb_target_group" "app" {
  name     = "hostel-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-302"
  }
}

# 3. Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# 4. Attach web servers to target group
resource "aws_lb_target_group_attachment" "web1" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.web_server_1.id
  port             = 5000
}

resource "aws_lb_target_group_attachment" "web2" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.web_server_2.id
  port             = 5000
}
