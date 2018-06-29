locals {
  app_name = "arch"

  default_host_parts = [
    "${local.app_name}",
    "${data.terraform_remote_state.stack.stack_name}",
    "${data.terraform_remote_state.stack.hosted_zone_name}",
  ]

  domain_host = "${coalesce(var.public_hostname, join(".", local.default_host_parts))}"
}

data "aws_acm_certificate" "ssl_certificate" {
  count       = "${var.public_hostname == "" ? 0 : 1}"
  domain      = "${local.domain_host}"
  most_recent = true
}

resource "random_pet" "app_version_name" {
  keepers = {
    source = "${data.archive_file.arch_source.output_md5}"
  }
}

resource "random_id" "secret_key_base" {
  byte_length = 32
}

module "arch_derivative_volume" {
  source  = "cloudposse/efs/aws"
  version = "0.3.3"

  namespace          = "${data.terraform_remote_state.stack.stack_name}"
  stage              = "${local.app_name}"
  name               = "derivatives"
  aws_region         = "${data.terraform_remote_state.stack.aws_region}"
  vpc_id             = "${data.terraform_remote_state.stack.vpc_id}"
  subnets            = "${data.terraform_remote_state.stack.private_subnets}"
  availability_zones = ["${data.terraform_remote_state.stack.azs}"]

  security_groups = [
    "${module.webapp.security_group_id}",
    "${module.worker.security_group_id}",
  ]

  zone_id = "${data.terraform_remote_state.stack.private_zone_id}"

  tags = "${local.common_tags}"
}

module "arch_working_volume" {
  source  = "cloudposse/efs/aws"
  version = "0.3.3"

  namespace          = "${data.terraform_remote_state.stack.stack_name}"
  stage              = "${local.app_name}"
  name               = "working"
  aws_region         = "${data.terraform_remote_state.stack.aws_region}"
  vpc_id             = "${data.terraform_remote_state.stack.vpc_id}"
  subnets            = "${data.terraform_remote_state.stack.private_subnets}"
  availability_zones = ["${data.terraform_remote_state.stack.azs}"]

  security_groups = [
    "${module.webapp.security_group_id}",
    "${module.worker.security_group_id}",
  ]

  zone_id = "${data.terraform_remote_state.stack.private_zone_id}"

  tags = "${local.common_tags}"
}

data "template_file" "dockerrun_aws_json" {
  template = "${file("./templates/Dockerrun.aws.json.tpl")}"

  vars {
    app_image = "${var.app_image}"
  }
}

resource "local_file" "dockerrun_aws_json" {
  content  = "${data.template_file.dockerrun_aws_json.rendered}"
  filename = "./application/Dockerrun.aws.json"
}

data "archive_file" "arch_source" {
  depends_on  = ["local_file.dockerrun_aws_json"]
  type        = "zip"
  source_dir  = "${path.module}/application"
  output_path = "${path.module}/build/${local.app_name}-${terraform.workspace}.zip"
}

resource "aws_s3_bucket_object" "arch_source" {
  bucket = "${data.terraform_remote_state.stack.application_source_bucket}"
  key    = "${local.app_name}-${random_pet.app_version_name.id}.zip"
  source = "${data.archive_file.arch_source.output_path}"
  etag   = "${data.archive_file.arch_source.output_md5}"
}

resource "aws_elastic_beanstalk_application" "arch" {
  name = "${local.namespace}-${local.app_name}"
}

resource "aws_elastic_beanstalk_application_version" "arch" {
  depends_on = [
    "aws_elastic_beanstalk_application.arch",
    "module.arch_derivative_volume",
    "module.arch_working_volume",
  ]

  description = "application version created by terraform"
  bucket      = "${data.terraform_remote_state.stack.application_source_bucket}"
  application = "${local.namespace}-${local.app_name}"
  key         = "${aws_s3_bucket_object.arch_source.id}"
  name        = "${random_pet.app_version_name.id}"
}

module "archdb" {
  source          = "../../modules/database"
  schema          = "${local.app_name}"
  host            = "${data.terraform_remote_state.stack.db_address}"
  port            = "${data.terraform_remote_state.stack.db_port}"
  master_username = "${data.terraform_remote_state.stack.db_master_username}"
  master_password = "${data.terraform_remote_state.stack.db_master_password}"

  connection = {
    user        = "ec2-user"
    host        = "${data.terraform_remote_state.stack.bastion_address}"
    private_key = "${file(data.terraform_remote_state.stack.ec2_private_keyfile)}"
  }
}

resource "aws_sqs_queue" "arch_ui_fifo_deadletter_queue" {
  name                        = "${data.terraform_remote_state.stack.stack_name}-arch-ui-dead-letter-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  tags                        = "${local.common_tags}"
}

resource "aws_sqs_queue" "arch_ui_fifo_queue" {
  name                        = "${data.terraform_remote_state.stack.stack_name}-arch-ui-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  delay_seconds               = 0
  visibility_timeout_seconds  = 3600
  redrive_policy              = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.arch_ui_fifo_deadletter_queue.arn}\",\"maxReceiveCount\":5}"
  tags                        = "${local.common_tags}"
}

resource "aws_s3_bucket" "arch_archives" {
  bucket = "${local.namespace}-${local.app_name}-archives"
  acl    = "private"
  tags   = "${local.common_tags}"

  lifecycle_rule {
    id                                     = "auto-delete-after-15-days"
    enabled                                = true
    abort_incomplete_multipart_upload_days = 3

    expiration {
      days = 7
    }
  }
}

resource "aws_s3_bucket" "arch_dropbox" {
  bucket = "${local.namespace}-${local.app_name}-dropbox"
  acl    = "private"
  tags   = "${local.common_tags}"

  lifecycle_rule {
    id                                     = "auto-delete-after-15-days"
    enabled                                = true
    abort_incomplete_multipart_upload_days = 3

    expiration {
      days = 15
    }
  }
}

data "aws_iam_policy_document" "arch_bucket_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["arn:aws:s3:::*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]

    resources = [
      "${aws_s3_bucket.arch_archives.arn}",
      "${aws_s3_bucket.arch_dropbox.arn}",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]

    resources = [
      "${aws_s3_bucket.arch_archives.arn}/*",
      "${aws_s3_bucket.arch_dropbox.arn}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "sqs:ListQueues",
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "arch_bucket_policy" {
  name   = "${data.terraform_remote_state.stack.stack_name}-${local.app_name}-bucket-access"
  policy = "${data.aws_iam_policy_document.arch_bucket_access.json}"
}

data "null_data_source" "ssm_parameters" {
  inputs = "${map(
    "arch/contact_email",       "digitalscholarship@northwestern.edu",
    "aws/buckets/archives",     "${aws_s3_bucket.arch_archives.id}",
    "aws/buckets/dropbox",      "${aws_s3_bucket.arch_dropbox.id}",
    "domain/host",              "${local.domain_host}",
    "geonames_username",        "nul_rdc",
    "solr/url",                 "${data.terraform_remote_state.stack.index_endpoint}arch",
    "zookeeper/connection_str", "${data.terraform_remote_state.stack.zookeeper_address}:2181/configs"
  )}"
}

resource "aws_ssm_parameter" "arch_config_setting" {
  count = 7
  name  = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/Settings/${element(keys(data.null_data_source.ssm_parameters.outputs), count.index)}"
  type  = "String"
  value = "${lookup(data.null_data_source.ssm_parameters.outputs, element(keys(data.null_data_source.ssm_parameters.outputs), count.index))}"
}
