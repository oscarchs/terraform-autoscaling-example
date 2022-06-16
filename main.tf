resource "aws_launch_configuration" "aws_autoscale_conf" {
  name          = "web_config"
  image_id      = "ami-0fa49cc9dc8d62c84"
  instance_type = "t2.micro"
  key_name = "autoscalegroupkey"
  associate_public_ip_address = true
}

resource "aws_autoscaling_group" "mygroup" {
  availability_zones        = ["us-east-2a"]
  name                      = "autoscalegroup"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 30
  health_check_type         = "EC2"
  force_delete              = true
  termination_policies      = ["OldestInstance"]
  launch_configuration      = aws_launch_configuration.aws_autoscale_conf.name
}

resource "aws_autoscaling_schedule" "mygroup_schedule" {
  scheduled_action_name  = "autoscalegroup_action"
  min_size               = 1
  max_size               = 2
  desired_capacity       = 1
  start_time             = "2022-06-16T21:00:00Z"
  autoscaling_group_name = aws_autoscaling_group.mygroup.name
}

resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "scaleup_policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120
  autoscaling_group_name = aws_autoscaling_group.mygroup.name
}


resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "scaledown_policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120
  autoscaling_group_name = aws_autoscaling_group.mygroup.name
}


resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
  alarm_name = "web_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = "50"
  alarm_actions = [
        "${aws_autoscaling_policy.scale_up_policy.arn}"
    ]
dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.mygroup.name}"
  }
}


resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_down" {
  alarm_name = "web_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = "10"
  alarm_actions = [
        "${aws_autoscaling_policy.scale_down_policy.arn}"
    ]
dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.mygroup.name}"
  }
}
