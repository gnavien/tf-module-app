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
variable "lb_dns_name" {}
variable "listener_arn" {}
variable "lb_rule_priority" {}
variable "kms_arn" {}
variable "extra_param_access" {}
variable "allow_prometheus_cidr" {}