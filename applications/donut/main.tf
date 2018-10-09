locals {
  app_name = "donut"

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
    source = "${data.archive_file.this_source.output_md5}"
  }
}

resource "random_id" "secret_key_base" {
  byte_length = 32
}

module "this_derivative_volume" {
  source  = "cloudposse/efs/aws"
  version = "0.3.6"

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
    "${module.batch_worker.security_group_id}",
    "${data.terraform_remote_state.stack.security_groups.bastion}",
  ]

  zone_id = "${data.terraform_remote_state.stack.private_zone_id}"

  tags = "${local.common_tags}"
}

module "this_working_volume" {
  source  = "cloudposse/efs/aws"
  version = "0.3.6"

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
    "${module.batch_worker.security_group_id}",
    "${data.terraform_remote_state.stack.security_groups.bastion}",
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

data "archive_file" "this_source" {
  depends_on  = ["local_file.dockerrun_aws_json"]
  type        = "zip"
  source_dir  = "${path.module}/application"
  output_path = "${path.module}/build/${local.app_name}-${terraform.workspace}.zip"
}

resource "aws_s3_bucket_object" "this_source" {
  bucket = "${data.terraform_remote_state.stack.application_source_bucket}"
  key    = "${local.app_name}-${random_pet.app_version_name.id}.zip"
  source = "${data.archive_file.this_source.output_path}"
  etag   = "${data.archive_file.this_source.output_md5}"
}

resource "aws_elastic_beanstalk_application" "this" {
  name = "${local.namespace}-${local.app_name}"
}

resource "aws_elastic_beanstalk_application_version" "this" {
  depends_on = [
    "aws_elastic_beanstalk_application.this",
    "module.this_derivative_volume",
    "module.this_working_volume",
  ]

  lifecycle {
    create_before_destroy = true
  }

  description = "application version created by terraform"
  bucket      = "${data.terraform_remote_state.stack.application_source_bucket}"
  application = "${local.namespace}-${local.app_name}"
  key         = "${aws_s3_bucket_object.this_source.id}"
  name        = "${random_pet.app_version_name.id}"
}

module "this_db" {
  source          = "../../modules/database"
  schema          = "${local.app_name}"
  host            = "${data.terraform_remote_state.stack.db_address}"
  port            = "${data.terraform_remote_state.stack.db_port}"
  master_username = "${data.terraform_remote_state.stack.db_master_username}"
  master_password = "${data.terraform_remote_state.stack.db_master_password}"

  connection = {
    user        = "ec2-user"
    host        = "${data.terraform_remote_state.stack.bastion_address}"
    private_key = "${file(var.ec2_private_keyfile)}"
  }
}

resource "aws_sqs_queue" "this_ui_fifo_deadletter_queue" {
  name                        = "${data.terraform_remote_state.stack.stack_name}-donut-ui-dead-letter-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  tags                        = "${local.common_tags}"
}

resource "aws_sqs_queue" "this_ui_fifo_queue" {
  name                        = "${data.terraform_remote_state.stack.stack_name}-donut-ui-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  delay_seconds               = 0
  visibility_timeout_seconds  = 3600
  redrive_policy              = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.this_ui_fifo_deadletter_queue.arn}\",\"maxReceiveCount\":5}"
  tags                        = "${local.common_tags}"
}

resource "aws_sqs_queue" "this_batch_fifo_deadletter_queue" {
  name                        = "${data.terraform_remote_state.stack.stack_name}-donut-batch-dead-letter-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  tags                        = "${local.common_tags}"
}

resource "aws_sqs_queue" "this_batch_fifo_queue" {
  name                        = "${data.terraform_remote_state.stack.stack_name}-donut-batch-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  delay_seconds               = 0
  visibility_timeout_seconds  = 3600
  redrive_policy              = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.this_batch_fifo_deadletter_queue.arn}\",\"maxReceiveCount\":5}"
  tags                        = "${local.common_tags}"
}

resource "aws_s3_bucket" "this_batch" {
  bucket = "${local.namespace}-donut-batch"
  acl    = "private"
  tags   = "${local.common_tags}"

  lifecycle_rule {
    id                                     = "batch-delete-after-365-days"
    enabled                                = true
    abort_incomplete_multipart_upload_days = 3

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket" "this_dropbox" {
  bucket = "${local.namespace}-donut-dropbox"
  acl    = "private"
  tags   = "${local.common_tags}"

  lifecycle_rule {
    id                                     = "dropbox-delete-after-30-days"
    enabled                                = true
    abort_incomplete_multipart_upload_days = 3

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket" "this_uploads" {
  bucket = "${local.namespace}-donut-uploads"
  acl    = "private"
  tags   = "${local.common_tags}"

  lifecycle_rule {
    id                                     = "uploads-delete-after-30-days"
    enabled                                = true
    abort_incomplete_multipart_upload_days = 3

    expiration {
      days = 30
    }
  }
}

data "aws_iam_policy_document" "this_bucket_access" {
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
      "${aws_s3_bucket.this_batch.arn}",
      "${aws_s3_bucket.this_dropbox.arn}",
      "${data.terraform_remote_state.stack.iiif_pyramid_bucket_arn}",
      "${aws_s3_bucket.this_uploads.arn}",
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
      "${aws_s3_bucket.this_batch.arn}/*",
      "${aws_s3_bucket.this_dropbox.arn}/*",
      "${data.terraform_remote_state.stack.iiif_pyramid_bucket_arn}/*",
      "${aws_s3_bucket.this_uploads.arn}/*",
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

resource "aws_iam_policy" "this_bucket_policy" {
  name   = "${data.terraform_remote_state.stack.stack_name}-${local.app_name}-bucket-access"
  policy = "${data.aws_iam_policy_document.this_bucket_access.json}"
}

data "aws_iam_policy_document" "this_batch_ingest_access" {
  statement {
    effect    = "Allow"
    actions   = ["iam:Passrole"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["sqs:*"]
    resources = ["${aws_sqs_queue.this_batch_fifo_queue.arn}"]
  }
}

module "this_batch_ingest" {
  source = "git://github.com/claranet/terraform-aws-lambda"

  function_name = "${data.terraform_remote_state.stack.stack_name}-${local.app_name}-batch-ingest"
  description   = "Batch Ingest trigger for ${local.app_name}"
  handler       = "index.handler"
  runtime       = "nodejs8.10"
  timeout       = 300

  attach_policy = true
  policy        = "${data.aws_iam_policy_document.this_batch_ingest_access.json}"

  source_path = "${path.module}/lambdas/batch_ingest_notification"

  environment {
    variables {
      JobClassName = "S3ImportJob"
      Secret       = "${random_id.secret_key_base.hex}"
      QueueUrl     = "${aws_sqs_queue.this_batch_fifo_queue.id}"
    }
  }
}

resource "aws_lambda_permission" "allow_trigger" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${module.this_batch_ingest.function_arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.this_batch.arn}"
}

resource "aws_s3_bucket_notification" "batch_ingest_notification" {
  bucket = "${aws_s3_bucket.this_batch.id}"

  lambda_function {
    lambda_function_arn = "${module.this_batch_ingest.function_arn}"
    filter_suffix       = ".csv"

    events = [
      "s3:ObjectCreated:Put",
      "s3:ObjectCreated:Post",
      "s3:ObjectCreated:CompleteMultipartUpload",
    ]
  }
}

data "null_data_source" "ssm_parameters" {
  inputs = "${map(
    "aws/buckets/batch",        "${aws_s3_bucket.this_batch.id}",
    "aws/buckets/dropbox",      "${aws_s3_bucket.this_dropbox.id}",
    "aws/buckets/pyramids",     "${data.terraform_remote_state.stack.iiif_pyramid_bucket}",
    "aws/buckets/uploads",      "${aws_s3_bucket.this_uploads.id}",
    "common_indexer/endpoint",  "${data.terraform_remote_state.stack.elasticsearch_endpoint}",
    "domain/host",              "${local.domain_host}",
    "geonames_username",        "nul_rdc",
    "iiif/endpoint",            "${data.terraform_remote_state.stack.iiif_endpoint}",
    "solr/url",                 "${data.terraform_remote_state.stack.index_endpoint}donut",
    "zookeeper/connection_str", "${data.terraform_remote_state.stack.zookeeper_address}:2181/configs"
  )}"
}

resource "aws_ssm_parameter" "this_config_setting" {
  count     = 10
  name      = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/Settings/${element(keys(data.null_data_source.ssm_parameters.outputs), count.index)}"
  type      = "String"
  value     = "${lookup(data.null_data_source.ssm_parameters.outputs, element(keys(data.null_data_source.ssm_parameters.outputs), count.index))}"
  overwrite = true
}
