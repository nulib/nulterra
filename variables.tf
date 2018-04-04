variable "stack_name" {
  type = "string"
}

variable "project_name" {
  type = "string"
}

variable "subnet_config" {
  type = "map"
  default = {
    "VPC"             = "10.0.0.0/16"
    "PrivateSubnetA"  = "10.0.1.0/24"
    "PublicSubnetA"   = "10.0.2.0/24"
    "PrivateSubnetB"  = "10.0.3.0/24"
    "PublicSubnetB"   = "10.0.4.0/24"
    "PrivateSubnetC"  = "10.0.5.0/24"
    "PublicSubnetC"   = "10.0.6.0/24"
  }
}

variable "aws_region" {
  type = "string"
  default = "us-east-1"
}

variable "azs" {
  type = "list"
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "hosted_zone_name" {
  type = "string"
}

variable "ec2_keyname" {
  type = "string"
}

variable "ec2_private_keyfile" {
  type = "string"
}

locals {
  common_tags = {
    "Owner" = "${var.stack_name}"
    "Project" = "${var.project_name}"
  }
}
