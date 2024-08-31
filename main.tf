# Steps to be followed to create a new ec2 instance

## IAM policy  https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
# In this component variable we have declared in variables.tf file
resource "aws_iam_policy" "policy" {
  name        = "${var.component}-${var.env}-ssm-pm-policy"
  path        = "/"
  description = "My test policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


## IAM role
## Security group
## EC2
## DNS records (route 53)
## Null Resource - Ansible