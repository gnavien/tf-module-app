variable "env" {}
variable "component" {}
variable "subnets" {}
variable "vpc_id" {}
variable "tags" {
  default = {}
}

variable "app_port" {}
variable "sg_subnet_cidr" {}
variable "instance_type" {}


variable "desired_capacity" {}
variable "max_size" {}
variable "min_size" {}
variable "kms_key_id" {}
variable "allow_ssh_cidr" {}