provider "aws" {
  region = "${data.terraform_remote_state.stack.aws_region}"
}

terraform {
  backend "s3" {}
}

variable "stack_bucket" {
  type   = "string"
}

variable "stack_key" {
  type    = "string"
  default = "stack.tfstate"
}

variable "stack_region" {
  type    = "string"
  default = "us-east-1"
}

variable "app_image" {
  type    = "string"
}

variable "public_hostname" {
  type    = "string"
  default = ""
}

variable "ec2_private_keyfile" {
  type    = "string"
}

variable "tags" {
  type    = "map"
  default = {}
}

data "terraform_remote_state" "stack" {
  backend = "s3"

  config {
    bucket = "${var.stack_bucket}"
    key    = "env:/${terraform.workspace}/${var.stack_key}"
    region = "${var.stack_region}"
  }
}

locals {
  namespace         = "${data.terraform_remote_state.stack.stack_name}-${data.terraform_remote_state.stack.environment}"
  public_zone_name  = "${data.terraform_remote_state.stack.stack_name}.${data.terraform_remote_state.stack.hosted_zone_name}"
  private_zone_name = "${data.terraform_remote_state.stack.stack_name}.vpc.${data.terraform_remote_state.stack.hosted_zone_name}"

  common_tags = "${merge(
    var.tags,
    map(
      "Terraform", "true",
      "Environment", "${local.namespace}",
      "Project", "Arch"
    )
  )}"

  stack_state = {
    bucket = "${var.stack_bucket}"
    key    = "env:/${terraform.workspace}/${var.stack_key}"
    region = "${var.stack_region}"
  }
}
