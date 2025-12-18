resource "aws_launch_template" "web_lt" {

  name = "${var.project}-launch-template"

  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = base64encode(data.template_file.user_data.rendered)

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project}-web"
    }
  }
}