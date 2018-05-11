terraform {
  backend "s3" {}
}

variable "remote_state_bucket" { type = "string" }
variable "remote_state_key"    { type = "string" }
variable "remote_state_region" { type = "string" }
variable "tags" {
  type = "map"
  default = {}
}

data "terraform_remote_state" "stack" {
  backend = "s3"
  config {
    bucket = "${var.remote_state_bucket}"
    key    = "${var.remote_state_key}"
    region = "${var.remote_state_region}"
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
}
