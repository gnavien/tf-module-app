#### 1  ####
# We need launch template to create ec2 instance

resource "aws_launch_template" "main" {
  name = "${var.component}-${var.env}"

  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }
  image_id = data.aws_ami.ami.id
  instance_type = var.instance_type
  vpc_security_group_ids = [ aws_security_group.main.id ]

  tag_specifications {
    resource_type = "instance"
    tags = merge({ Name = "${var.component}-${var.env}", Monitor = "true" }, var.tags) # Monitor tag is for prometheus monitoring key word
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    env       = var.env
    component = var.component
  }))

  # Below block is to encrypt our disk
  #  block_device_mappings {
  #    device_name = "/dev/sda1"
  #    ebs {
  #      volume_size = var.volume_size
  #      encrypted = "true"
  #      kms_key_id = var.kms_key_id
  #    }
  #  }

}

### Security group
#### 2 #####

resource "aws_security_group" "main" {
  name        = "${var.component}-${var.env}-sg"
  description = "${var.component}-${var.env}-sg"
  vpc_id = var.vpc_id # If we dont mention our required vpc it will create in default vpc

  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = var.sg_subnet_cidr
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allow_ssh_cidr # We wanted workstation to access this node
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.component}-${var.env}-sg"
  }
}

#### 3  #####

resource "aws_autoscaling_group" "main" {
  name                = "${var.component}-${var.env}"
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = var.subnets # At least one Availability Zone or VPC Subnet is required
  target_group_arns   = [ aws_lb_target_group.main.arn ] # This way your autoscaling group will be attached to the target group arn automatically

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
}

#### 4 #####
# We need to create target group before creating the instance

resource "aws_lb_target_group" "main" {
  name     = "${var.component}-${var.env}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}




#### 5 #####


resource "aws_route53_record" "dns"{
  zone_id = "Z0882917IBD3RSFVPY9W" # We have to enter the default zone ID
  name    = "${var.component}-${var.env}-dns"
  type    = "CNAME"
  ttl     = "30"
  records = [var.lb_dns_name]

}

#### 6 #####
# Once we have added the target groups we need to add listener rule

resource "aws_lb_listener_rule" "main" {
  listener_arn = var.listener_arn # We are getting the listener arn from the alb module so we will take from the output.tf file of alb module
  priority     = var.lb_rule_priority   # In which order you want to execute the component and the number is given as input in main.tfvars

  action {
    type             = "forward"  # where you to forward the component
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    path_pattern {
      values = ["${var.component}-${var.env}.saty.fun"] # saty.fun or navien.site should be mentioned based on the route 53 registration
    }
  }


}















































### For Instance we would be doing through auto scaling group

#
#
### DNS records (route 53)
#
#resource "aws_route53_record" "dns" {
#  zone_id = "Z00238782DN7KNOSJPFLV"
#  name    = "${var.component}-dev"
#  type    = "A"
#  ttl     = 30
#  records = [aws_instance.instance.private_ip]# We are accessing all the ec2 instances using the private IP address
#}


