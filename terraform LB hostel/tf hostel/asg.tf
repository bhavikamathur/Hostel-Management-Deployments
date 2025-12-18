resource "aws_autoscaling_group" "web_asg" {
  name             = "${var.project}-asg"
  max_size         = 3
  min_size         = 1
  desired_capacity = 1

  vpc_zone_identifier = [for s in aws_subnet.public : s.id]

  target_group_arns = [aws_lb_target_group.tg.arn]

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.project}-web"
    propagate_at_launch = true
  }
}