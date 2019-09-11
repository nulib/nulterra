provider "aws" {
  region = "${var.stack_region}"
}

terraform {
  backend "s3" {}
}

variable "stack_bucket" {
  type = "string"
}

variable "stack_key" {
  type    = "string"
  default = "stack.tfstate"
}

variable "stack_region" {
  type    = "string"
  default = "us-east-1"
}

variable "solr_capacity" {
  default = 3
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

data "aws_elastic_beanstalk_solution_stack" "multi_docker" {
  most_recent = true
  name_regex  = "^64bit Amazon Linux (.*) Multi-container Docker (.*)$"
}

locals {
  namespace         = "${data.terraform_remote_state.stack.stack_name}-${data.terraform_remote_state.stack.environment}"
  public_zone_name  = "${data.terraform_remote_state.stack.stack_name}.${data.terraform_remote_state.stack.hosted_zone_name}"
  private_zone_name = "${data.terraform_remote_state.stack.stack_name}.vpc.${data.terraform_remote_state.stack.hosted_zone_name}"

  common_tags = "${merge(
    data.terraform_remote_state.stack.tags,
    map(
      "Terraform", "true",
      "Environment", "${local.namespace}",
      "Project", "Infrastructure"
    )
  )}"

  stack_state = {
    bucket = "${var.stack_bucket}"
    key    = "env:/${terraform.workspace}/${var.stack_key}"
    region = "${var.stack_region}"
  }
}
