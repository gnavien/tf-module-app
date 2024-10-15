
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
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = var.volume_size
      encrypted = "true"
      kms_key_id = var.kms_key_id
    }
  }

}

#### 3  #####

resource "aws_autoscaling_group" "main" {
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  vpc_zone_identifier = var.subnets # At least one Availability Zone or VPC Subnet is required

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
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


