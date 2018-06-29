provider "aws" {
  region = "${data.terraform_remote_state.stack.aws_region}"
}

terraform {
  backend "s3" {}
}

variable "app_image" {
  type    = "string"
  default = "nulib/donut"
}

variable "public_hostname" {
  type = "string"
  default = ""
}

variable "ssl_certificate" {
  type = "string"
  default = ""
}

variable "stack_bucket" { type = "string" }
variable "stack_key"    { type = "string" }
variable "stack_region" { type = "string" }
variable "tags" {
  type = "map"
  default = {}
}

data "terraform_remote_state" "stack" {
  backend = "s3"
  config {
    bucket = "${var.stack_bucket}"
    key    = "${var.stack_key}"
    region = "${var.stack_region}"
  }
}

locals {
  namespace         = "${data.terraform_remote_state.stack.stack_name}-${data.terraform_remote_state.stack.environment}"
  public_zone_name  = "${data.terraform_remote_state.stack.stack_name}.${data.terraform_remote_state.stack.hosted_zone_name}"
  private_zone_name = "${data.terraform_remote_state.stack.stack_name}.vpc.${data.terraform_remote_state.stack.hosted_zone_name}"
  common_tags       = "${merge(
    var.tags,
    map(
      "Terraform", "true",
      "Environment", "${local.namespace}",
      "Project", "Infrastructure"
    )
  )}"
  stack_state = {
    bucket = "${var.stack_bucket}"
    key = "${var.stack_key}"
    region = "${var.stack_region}"
  }
}
