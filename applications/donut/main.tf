locals {
  app_name = "donut"
}

resource "random_id" "secret_key_base" {
  byte_length = 32
}

resource "random_pet" "app_version_name" {
  keepers = {
    source = "${data.archive_file.donut_source.output_md5}"
  }
}

module "donut_derivative_volume" {
  source  = "cloudposse/efs/aws"
  version = "0.3.3"

  namespace          = "${data.terraform_remote_state.stack.stack_name}"
  stage              = "${local.app_name}"
  name               = "derivatives"
  aws_region         = "${data.terraform_remote_state.stack.aws_region}"
  vpc_id             = "${data.terraform_remote_state.stack.vpc_id}"
  subnets            = "${data.terraform_remote_state.stack.private_subnets}"
  availability_zones = ["${data.terraform_remote_state.stack.azs}"]
  security_groups    = [
    "${module.webapp.security_group_id}",
    "${module.worker.security_group_id}",
    "${module.batch_worker.security_group_id}"
  ]

  zone_id = "${data.terraform_remote_state.stack.private_zone_id}"

  tags = "${local.common_tags}"
}

module "donut_working_volume" {
  source  = "cloudposse/efs/aws"
  version = "0.3.3"

  namespace          = "${data.terraform_remote_state.stack.stack_name}"
  stage              = "${local.app_name}"
  name               = "working"
  aws_region         = "${data.terraform_remote_state.stack.aws_region}"
  vpc_id             = "${data.terraform_remote_state.stack.vpc_id}"
  subnets            = "${data.terraform_remote_state.stack.private_subnets}"
  availability_zones = ["${data.terraform_remote_state.stack.azs}"]
  security_groups    = [
    "${module.webapp.security_group_id}",
    "${module.worker.security_group_id}",
    "${module.batch_worker.security_group_id}"
  ]

  zone_id = "${data.terraform_remote_state.stack.private_zone_id}"

  tags = "${local.common_tags}"
}

data "archive_file" "donut_source" {
  type        = "zip"
  source_dir  = "${path.module}/application"
  output_path = "${path.module}/build/${local.app_name}.zip"
}

resource "aws_s3_bucket_object" "donut_source" {
  bucket = "${data.terraform_remote_state.stack.application_source_bucket}"
  key    = "${local.app_name}-${random_pet.app_version_name.id}.zip"
  source = "${data.archive_file.donut_source.output_path}"
  etag   = "${data.archive_file.donut_source.output_md5}"
}

resource "aws_elastic_beanstalk_application" "donut" {
  name = "${local.namespace}-${local.app_name}"
}

resource "aws_elastic_beanstalk_application_version" "donut" {
  depends_on      = ["aws_elastic_beanstalk_application.donut"]
  description     = "application version created by terraform"
  bucket          = "${data.terraform_remote_state.stack.application_source_bucket}"
  application     = "${local.namespace}-${local.app_name}"
  key             = "${local.app_name}-${random_pet.app_version_name.id}.zip"
  name            = "${random_pet.app_version_name.id}"
}

module "donutdb" {
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

resource "aws_sqs_queue" "donut_ui_fifo_deadletter_queue" {
  name                        = "${data.terraform_remote_state.stack.stack_name}-donut-ui-dead-letter-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  tags                        = "${local.common_tags}"
}

resource "aws_sqs_queue" "donut_ui_fifo_queue" {
  name                        = "${data.terraform_remote_state.stack.stack_name}-donut-ui-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  delay_seconds               = 0
  visibility_timeout_seconds  = 3600
  redrive_policy              = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.donut_ui_fifo_deadletter_queue.arn}\",\"maxReceiveCount\":5}"
  tags                        = "${local.common_tags}"
}

resource "aws_sqs_queue" "donut_batch_fifo_deadletter_queue" {
  name                        = "${data.terraform_remote_state.stack.stack_name}-donut-batch-dead-letter-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  tags                        = "${local.common_tags}"
}

resource "aws_sqs_queue" "donut_batch_fifo_queue" {
  name                        = "${data.terraform_remote_state.stack.stack_name}-donut-batch-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  delay_seconds               = 0
  visibility_timeout_seconds  = 3600
  redrive_policy              = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.donut_batch_fifo_deadletter_queue.arn}\",\"maxReceiveCount\":5}"
  tags                        = "${local.common_tags}"
}

resource "aws_s3_bucket" "donut_batch" {
  bucket = "${local.namespace}-donut-batch"
  acl    = "private"
  tags   = "${local.common_tags}"
}

resource "aws_s3_bucket" "donut_dropbox" {
  bucket = "${local.namespace}-donut-dropbox"
  acl    = "private"
  tags   = "${local.common_tags}"
}

resource "aws_s3_bucket" "donut_uploads" {
  bucket = "${local.namespace}-donut-uploads"
  acl    = "private"
  tags   = "${local.common_tags}"
}

data "aws_iam_policy_document" "donut_bucket_access" {
  statement {
    effect = "Allow"
    actions = ["s3:ListAllMyBuckets"]
    resources = ["arn:aws:s3:::*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      "${aws_s3_bucket.donut_batch.arn}",
      "${aws_s3_bucket.donut_dropbox.arn}",
      "${data.terraform_remote_state.stack.iiif_pyramid_bucket_arn}",
      "${aws_s3_bucket.donut_uploads.arn}"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${aws_s3_bucket.donut_batch.arn}/*",
      "${aws_s3_bucket.donut_dropbox.arn}/*",
      "${data.terraform_remote_state.stack.iiif_pyramid_bucket_arn}/*",
      "${aws_s3_bucket.donut_uploads.arn}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = [
      "sqs:ListQueues",
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "donut_bucket_policy" {
  name = "${data.terraform_remote_state.stack.stack_name}-${local.app_name}-bucket-access"
  policy = "${data.aws_iam_policy_document.donut_bucket_access.json}"
}

resource "aws_ssm_parameter" "aws_buckets_batch" {
  name = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/Settings/aws/buckets/batch"
  type = "String"
  value = "${aws_s3_bucket.donut_batch.id}"
}

resource "aws_ssm_parameter" "aws_buckets_dropbox" {
  name = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/Settings/aws/buckets/dropbox"
  type = "String"
  value = "${aws_s3_bucket.donut_dropbox.id}"
}

resource "aws_ssm_parameter" "aws_buckets_pyramids" {
  name = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/Settings/aws/buckets/pyramids"
  type = "String"
  value = "${data.terraform_remote_state.stack.iiif_pyramid_bucket}"
}

resource "aws_ssm_parameter" "aws_buckets_uploads" {
  name = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/Settings/aws/buckets/uploads"
  type = "String"
  value = "${aws_s3_bucket.donut_uploads.id}"
}

resource "aws_ssm_parameter" "domain_host" {
  name = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/Settings/domain/host"
  type = "String"
  value = "${local.app_name}.${data.terraform_remote_state.stack.stack_name}.${data.terraform_remote_state.stack.hosted_zone_name}"
}

resource "aws_ssm_parameter" "geonames_username" {
  name = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/Settings/geonames_username"
  type = "String"
  value = "nul_rdc"
}

resource "aws_ssm_parameter" "iiif_endpoint" {
  name = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/Settings/iiif/endpoint"
  type = "String"
  value = "${data.terraform_remote_state.stack.iiif_endpoint}"
}

resource "aws_ssm_parameter" "solr_collection_options_replication_factor" {
  name = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/Settings/solr/collection_options/replication_factor"
  type = "String"
  value = "3"
}

resource "aws_ssm_parameter" "solr_collection_options_rule" {
  name = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/Settings/solr/collection_options/rule"
  type = "String"
  value = "shard:*,replica:<2,cores:<5~"
}

resource "aws_ssm_parameter" "solr_url" {
  name = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/Settings/solr/url"
  type = "String"
  value = "${data.terraform_remote_state.stack.index_endpoint}donut"
}

resource "aws_ssm_parameter" "zookeeper_connection_str" {
  name = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/Settings/zookeeper/connection_str"
  type = "String"
  value = "${data.terraform_remote_state.stack.zookeeper_address}:2181/configs"
}
