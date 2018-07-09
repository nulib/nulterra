provider "aws" {
  region = "${data.terraform_remote_state.stack.aws_region}"
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

data "aws_ssm_parameter" "app_image" {
  name = "/terraform/${data.terraform_remote_state.stack.stack_name}/donut/app_image"
}

data "aws_ssm_parameter" "public_hostname" {
  name = "/terraform/${data.terraform_remote_state.stack.stack_name}/donut/public_hostname"
}

data "aws_ssm_parameter" "tag_names" {
  name = "/terraform/${data.terraform_remote_state.stack.stack_name}/donut/tag_names"
}

data "aws_ssm_parameter" "ec2_private_keyfile" {
  name = "/terraform/${data.terraform_remote_state.stack.stack_name}/ec2_private_keyfile"
}

data "aws_ssm_parameter" "tag_values" {
  name = "/terraform/${data.terraform_remote_state.stack.stack_name}/donut/tag_values"
}

module "environment" {
  source = "git::https://github.com/nulib/terraform-local-environment.git?ref=master"
  vars   = "HOME"
}

locals {
  app_image           = "${data.aws_ssm_parameter.app_image.value}"
  public_hostname     = "${data.aws_ssm_parameter.public_hostname.value == "__EMPTY__" ? "" : data.aws_ssm_parameter.public_hostname.value}"
  ec2_private_keyfile = "${replace(data.aws_ssm_parameter.ec2_private_keyfile.value, "~/", "${module.environment.result["HOME"]}/")}"
  tags                = "${zipmap(split(",", data.aws_ssm_parameter.tag_names.value), split(",", data.aws_ssm_parameter.tag_values.value))}"
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
    local.tags,
    map(
      "Terraform", "true",
      "Environment", "${local.namespace}",
      "Project", "DONUT"
    )
  )}"

  stack_state = {
    bucket = "${var.stack_bucket}"
    key    = "env:/${terraform.workspace}/${var.stack_key}"
    region = "${var.stack_region}"
  }
}
