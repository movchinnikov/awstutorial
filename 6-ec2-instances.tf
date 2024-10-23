resource "aws_instance" "instances" {
    for_each = toset(data.aws_subnets.public_subnets.ids)
    ami = data.aws_ami.ami_amazon_linux.id
    instance_type = "${var.instance_type}"
    subnet_id = each.value
    key_name = aws_key_pair.generated_key.key_name
    security_groups = [aws_security_group.sg.id]
    user_data = file("${path.module}/user_data.sh")
    
    tags = {
        Name = "${var.prefix}-instance-${each.value}"
    }
}

resource "aws_lb_target_group_attachment" "alb_tg_attachment" {
  for_each = {
    for k, v in aws_instance.instances :
    k => v
  }
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id = each.value.id
  port = 80
}