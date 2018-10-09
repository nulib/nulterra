variable "aws_region" {
  type    = "string"
  default = "us-east-1"
}

variable "azs" {
  type    = "list"
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "bastion_instance_type" {
  type    = "string"
  default = "t2.small"
}

variable "db_master_username" {
  type    = "string"
  default = "dbadmin"
}

variable "ec2_keyname" {
  type    = "string"
}

variable "ec2_private_keyfile" {
  type    = "string"
}

variable "enable_iiif_cloudfront" {
  type    = "string"
  default = false
}

variable "environment" {
  type    = "string"
}

variable "hosted_zone_name" {
  type    = "string"
}

variable "stack_name" {
  type    = "string"
  default = "stack"
}

variable "pager_alert" {
  type    = "list"
}

variable "tags" {
  type    = "map"
  default = {}
}

variable "vpc_cidr_block" {
  type    = "string"
  default = "10.1.0.0/16"
}

variable "vpc_public_subnets" {
  type    = "list"
  default = ["10.1.2.0/24", "10.1.4.0/24", "10.1.6.0/24"]
}

variable "vpc_private_subnets" {
  type    = "list"
  default = ["10.1.1.0/24", "10.1.3.0/24", "10.1.5.0/24"]
}

locals {
  namespace         = "${var.stack_name}-${var.environment}"
  public_zone_name  = "${var.stack_name}.${var.hosted_zone_name}"
  private_zone_name = "${var.stack_name}.vpc.${var.hosted_zone_name}"

  common_tags = "${merge(
    var.tags,
    map(
      "Terraform", "true",
      "Environment", "${local.namespace}",
      "Project", "Infrastructure"
    )
  )}"
}
