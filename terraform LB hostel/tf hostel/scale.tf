resource "aws_autoscaling_policy" "cpu_scale_out" {
  name                    = "${var.project}-cpu-scale-out"
  autoscaling_group_name  = aws_autoscaling_group.web_asg.name
  adjustment_type         = "ChangeInCapacity"
  scaling_adjustment      = 1
  cooldown                = 120
  metric_aggregation_type = "Average"
}
resource "aws_autoscaling_policy" "cpu_scale_in" {
  name                    = "${var.project}-cpu-scale-in"
  autoscaling_group_name  = aws_autoscaling_group.web_asg.name
  adjustment_type         = "ChangeInCapacity"
  scaling_adjustment      = -1
  cooldown                = 120
  metric_aggregation_type = "Average"
}