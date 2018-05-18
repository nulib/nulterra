terraform {
  backend "s3" {}
}

provider "aws" {
  region = "${var.aws_region}"
}

data "aws_elastic_beanstalk_solution_stack" "multi_docker" {
  most_recent   = true
  name_regex    = "^64bit Amazon Linux (.*) Multi-container Docker (.*)$"
}

resource "aws_s3_bucket" "app_sources" {
  bucket = "${local.namespace}-sources"
  acl    = "private"
  tags   = "${local.common_tags}"
}
