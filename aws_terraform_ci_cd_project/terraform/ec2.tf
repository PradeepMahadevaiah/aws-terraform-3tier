resource "aws_launch_template" "web" {
  name_prefix   = "web-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type

  user_data = base64encode(file("../scripts/user_data.sh"))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "web-instance"
    }
  }
}

resource "aws_autoscaling_group" "web_asg" {
  desired_capacity     = 2
  max_size             = 3
  min_size             = 1
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.web_tg.arn]
  health_check_type   = "EC2"
  tag {
    key                 = "Name"
    value               = "asg-instance"
    propagate_at_launch = true
  }
}
