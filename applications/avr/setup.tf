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
  name = "/terraform/${data.terraform_remote_state.stack.stack_name}/avr/app_image"
}

data "aws_ssm_parameter" "public_hostname" {
  name = "/terraform/${data.terraform_remote_state.stack.stack_name}/avr/public_hostname"
}

data "aws_ssm_parameter" "tag_names" {
  name = "/terraform/${data.terraform_remote_state.stack.stack_name}/avr/tag_names"
}

data "aws_ssm_parameter" "tag_values" {
  name = "/terraform/${data.terraform_remote_state.stack.stack_name}/avr/tag_values"
}

data "aws_ssm_parameter" "streaming_hostname" {
  name = "/terraform/${data.terraform_remote_state.stack.stack_name}/avr/streaming_hostname"
}

data "aws_ssm_parameter" "email_comments" {
  name = "/terraform/${data.terraform_remote_state.stack.stack_name}/avr/email_comments"
}

data "aws_ssm_parameter" "email_notification" {
  name = "/terraform/${data.terraform_remote_state.stack.stack_name}/avr/email_notification"
}

data "aws_ssm_parameter" "email_support" {
  name = "/terraform/${data.terraform_remote_state.stack.stack_name}/avr/email_support"
}

data "aws_ssm_parameter" "initial_user" {
  name = "/terraform/${data.terraform_remote_state.stack.stack_name}/avr/initial_user"
}

data "aws_ssm_parameter" "trusted_signers" {
  name = "/terraform/${data.terraform_remote_state.stack.stack_name}/avr/trusted_signers"
}

data "aws_ssm_parameter" "lti_key" {
  name = "/terraform/${data.terraform_remote_state.stack.stack_name}/avr/lti_key"
}

data "aws_ssm_parameter" "lti_secret" {
  name = "/terraform/${data.terraform_remote_state.stack.stack_name}/avr/lti_secret"
}

data "aws_ssm_parameter" "ec2_private_keyfile" {
  name = "/terraform/${data.terraform_remote_state.stack.stack_name}/ec2_private_keyfile"
}

locals {
  app_image           = "${data.aws_ssm_parameter.app_image.value}"
  public_hostname     = "${data.aws_ssm_parameter.public_hostname.value == "__EMPTY__" ? "" : data.aws_ssm_parameter.public_hostname.value}"
  streaming_hostname  = "${data.aws_ssm_parameter.streaming_hostname.value == "__EMPTY__" ? "" : data.aws_ssm_parameter.streaming_hostname.value}"
  initial_user        = "${data.aws_ssm_parameter.initial_user.value == "__EMPTY__" ? "" : data.aws_ssm_parameter.initial_user.value}"
  trusted_signers     = "${split(",", data.aws_ssm_parameter.trusted_signers.value)}"
  lti_key             = "${data.aws_ssm_parameter.lti_key.value == "__EMPTY__" ? "" : data.aws_ssm_parameter.lti_key.value}"
  lti_secret          = "${data.aws_ssm_parameter.lti_secret.value == "__EMPTY__" ? "" : data.aws_ssm_parameter.lti_secret.value}"
  ec2_private_keyfile = "${replace(data.aws_ssm_parameter.ec2_private_keyfile.value, "~/", "${module.environment.result["HOME"]}/")}"
  tags                = "${zipmap(split(",", data.aws_ssm_parameter.tag_names.value), split(",", data.aws_ssm_parameter.tag_values.value))}"

  email = {
    comments     = "${data.aws_ssm_parameter.email_comments.value}"
    notification = "${data.aws_ssm_parameter.email_notification.value}"
    support      = "${data.aws_ssm_parameter.email_support.value}"
  }
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
      "Project", "AVR"
    )
  )}"

  stack_state = {
    bucket = "${var.stack_bucket}"
    key    = "env:/${terraform.workspace}/${var.stack_key}"
    region = "${var.stack_region}"
  }
}
