resource "aws_launch_template" "launch_template" {
    name = "${var.prefix}-launch-template"
    image_id = data.aws_ami.ami_amazon_linux.id
    instance_type = "${var.instance_type}"
    key_name = aws_key_pair.generated_key.key_name
        network_interfaces {
        security_groups = [aws_security_group.sg.id]
        associate_public_ip_address = true
    }
    user_data = base64encode(
        templatefile("user_data.sh", {
            DB_HOST = data.aws_rds_cluster.postgres_cluster.endpoint
        })
    )
    depends_on = [ data.aws_rds_cluster.postgres_cluster ]
}

resource "aws_autoscaling_group" "asg" {
    name = "${var.prefix}-asg"
    desired_capacity = 2
    max_size = 3
    min_size = 1
    vpc_zone_identifier = data.aws_subnets.public_subnets.ids
    launch_template {
        id = aws_launch_template.launch_template.id
    }
    

    tag {
        key = "Name"
        value = "${var.prefix}-asg"
        propagate_at_launch = true
    }

    health_check_type = "EC2"
    health_check_grace_period = 300

    depends_on = [ data.aws_rds_cluster.postgres_cluster ]
}

resource "aws_autoscaling_policy" "scale_out" {
    name = "${var.prefix}-scale-out-policy"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_autoscaling_policy" "scale_in" {
    name = "${var.prefix}-scale-in-policy"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_autoscaling_attachment" "autoscaling_attachment" {
    autoscaling_group_name = aws_autoscaling_group.asg.name
    lb_target_group_arn = aws_lb_target_group.alb_tg.arn
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm_high" {
    alarm_name = "${var.prefix}_cpu_alarm_high"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "120"
    statistic = "Average"
    threshold = "70"
    alarm_actions = [aws_autoscaling_policy.scale_out.arn]
    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.asg.name
    }
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm_low" {
  alarm_name = "${var.prefix}_cpu_alarm_low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = "2"
  metric_name= "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "30"
  alarm_actions = [aws_autoscaling_policy.scale_in.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}