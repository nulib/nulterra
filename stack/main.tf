terraform {
  backend "s3" {}
}

provider "aws" {
  region = "${var.aws_region}"
}

data "aws_elastic_beanstalk_solution_stack" "multi_docker" {
  most_recent = true
  name_regex  = "^64bit Amazon Linux (.*) Multi-container Docker (.*)$"
}

resource "aws_s3_bucket" "app_sources" {
  bucket = "${local.namespace}-sources"
  acl    = "private"
  tags   = "${local.common_tags}"
}

resource "aws_cloudwatch_log_group" "stack_log_group" {
  name = "${local.namespace}"
  retention_in_days = "90"
}

data "aws_elb_service_account" "main" {}

data "aws_iam_policy_document" "elb_logs" {
  statement {
    sid = ""

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${local.namespace}-elb-logs/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["${data.aws_elb_service_account.main.arn}"]
    }

    effect = "Allow"
  }
}

resource "aws_s3_bucket" "elb_logs" {
  bucket = "${local.namespace}-elb-logs"
  acl    = "private"

  policy = "${data.aws_iam_policy_document.elb_logs.json}"
}
