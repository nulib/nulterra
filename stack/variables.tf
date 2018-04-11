variable "stack_name" {
  type = "string"
}

variable "environment" {
  type = "string"
}

variable "vpc_cidr_block" {
  type    = "string"
  default = "10.0.0.0/16"
}

variable "subnet_config" {
  type = "map"
  default = {
    "public_subnets"   = ["10.0.2.0/24", "10.0.4.0/24", "10.0.6.0/24"],
    "private_subnets"  = ["10.0.1.0/24", "10.0.3.0/24", "10.0.5.0/24"]
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

variable "tags" {
  type = "map"
  default = {}
}

locals {
  public_zone_name  = "${var.stack_name}.${var.hosted_zone_name}"
  private_zone_name = "${var.stack_name}.vpc.${var.hosted_zone_name}"
  common_tags = "${merge(
    var.tags,
    map(
      "Terraform", "true",
      "Environment", "${var.stack_name}-${var.environment}",
      "Project", "Infrastructure"
    )
  )}"
}
