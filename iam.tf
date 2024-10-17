# Steps to be followed to create a new ec2 instance

## IAM policy  https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
# In this component variable we have declared in variables.tf.tf file
# For creating a policy, first create it manually and then copy the json file
# ARN is unique to each AWS account 968585591903 is the account id


resource "aws_iam_policy" "policy" {
  name        = "${var.component}-${var.env}-ssm-pm-policy"
  path        = "/"
  description = "${var.component}-${var.env}-ssm-pm-policy"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter",
          "kms:Decrypt"  # since parameter were all encrypted so  we need access to decrypt the key
        ]
        #
        "Resource" : concat([
          "arn:aws:ssm:us-east-1:968585591903:parameter/roboshop.${var.env}.${var.component}.*",
           var.kms_arn ], var.extra_param_access)
      }

    ]
    # mysql and docdb would require extra parameters or permissions to access
  })
}




## IAM role
## We have created a role manually, select trust relationship tab and copy the role information
##  After creation of role we need to attach the policy to the role.

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
  name = "${var.component}-${var.env}-ec2-role"
  role = aws_iam_role.role.name
}

resource "aws_iam_role_policy_attachment" "policy-attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}