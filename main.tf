# Steps to be followed to create a new ec2 instance

## IAM policy  https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
# In this component variable we have declared in variables.tf file
# For creating a policy, first create it manually and then copy the json file
# ARN is unique to each AWS account
resource "aws_iam_policy" "policy" {
  name        = "${var.component}-${var.env}-ssm-pm-policy"
  path        = "/"
  description = "${var.component}-${var.env}-ssm-pm-policy"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        "Resource": "arn:aws:ssm:us-east-1:968585591903:parameter/roboshop-${var.env}.${var.component}.*"
      }
    ]
  })
}


## IAM role
## We have created a role manually, select trust relationship tab and copy the role information
##  After creaton of role we need to attach the policy to the role.

resource "aws_iam_role" "role" {
  name = "${var.component}-${var.env}-EC2-Role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.component}-${var.env}-instance_profile"
  role = aws_iam_role.role.name
}

resource "aws_iam_role_policy_attachment" "policy-attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}
## Security group


resource "aws_security_group" "sg" {
  name        = "${var.component}-${var.env}-sg"
  description = "${var.component}-${var.env}-sg"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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
## EC2
## For EC2 we would require data for aws ami which is stored in data.tf file

resource "aws_instance" "instance" {
  ami           = data.aws_ami.ami.id
  instance_type = "t3.small"
  vpc_security_group_ids = [aws_security_group.sg.id] # list of security groups
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  tags = {
    Name = "${var.component}-${var.env}"  # Instance Name is called Sample we have the variable in the main.tf file
  }
}


## DNS records (route 53)

resource "aws_route53_record" "dns" {
  zone_id = "Z00238782DN7KNOSJPFLV"
  name    = "${var.component}-dev"
  type    = "A"
  ttl     = 30
  records = [aws_instance.instance.private_ip]# We are accessing all the ec2 instances using the private IP address
}
## Null Resource - Ansible

resource "null_resource" "ansible" {
  depends_on = [aws_instance.instance,aws_route53_record.dns] # We have written this once ec2 instances and route 53 records have been created we need to start the remote execution.
   provisioner "remote-exec" {

    connection {
      type     = "ssh"
      user     = "centos"
      password = "DevOps321"
      host     = aws_instance.instance.public_ip
    }


    inline = [
      "sudo labauto ansible",
      "ansible-pull -i localhost, -U https://github.com/gnavien/roboshop-ansible.git main.yml -e env=${var.env} -e role_name=${var.component}"
    ]
  }
}