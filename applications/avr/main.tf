locals {
  app_name = "avr"

  default_host_parts = [
    "${local.app_name}",
    "${data.terraform_remote_state.stack.stack_name}",
    "${data.terraform_remote_state.stack.hosted_zone_name}",
  ]

  domain_host = "${coalesce(local.public_hostname, join(".", local.default_host_parts))}"
}

data "aws_acm_certificate" "ssl_certificate" {
  count       = "${local.public_hostname == "" ? 0 : 1}"
  domain      = "${local.domain_host == "media.northwestern.edu" ? "avalon.repo.rdc.library.northwestern.edu" : local.domain_host}"
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

data "template_file" "dockerrun_aws_json" {
  template = "${file("./templates/Dockerrun.aws.json.tpl")}"

  vars {
    app_image = "${local.app_image}"
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
  ]

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
    private_key = "${file(local.ec2_private_keyfile)}"
  }
}

resource "aws_sqs_queue" "this_ui_deadletter_queue" {
  name       = "${data.terraform_remote_state.stack.stack_name}-avr-ui-dead-letter-queue"
  fifo_queue = false
  tags       = "${local.common_tags}"
}

resource "aws_sqs_queue" "this_ui_queue" {
  name                       = "${data.terraform_remote_state.stack.stack_name}-avr-ui-queue"
  fifo_queue                 = false
  delay_seconds              = 0
  visibility_timeout_seconds = 3600
  redrive_policy             = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.this_ui_deadletter_queue.arn}\",\"maxReceiveCount\":5}"
  tags                       = "${local.common_tags}"
}

resource "aws_sqs_queue" "this_batch_deadletter_queue" {
  name       = "${data.terraform_remote_state.stack.stack_name}-avr-batch-dead-letter-queue"
  fifo_queue = false
  tags       = "${local.common_tags}"
}

resource "aws_sqs_queue" "this_batch_queue" {
  name                       = "${data.terraform_remote_state.stack.stack_name}-avr-batch-queue"
  fifo_queue                 = false
  delay_seconds              = 0
  visibility_timeout_seconds = 3600
  redrive_policy             = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.this_batch_deadletter_queue.arn}\",\"maxReceiveCount\":5}"
  tags                       = "${local.common_tags}"
}

resource "aws_s3_bucket" "this_masterfiles" {
  bucket = "${local.namespace}-avr-masterfiles"
  acl    = "private"
  tags   = "${local.common_tags}"

  cors_rule {
    allowed_origins = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
  }
}

resource "aws_s3_bucket" "this_derivatives" {
  #  bucket = "${local.namespace}-avr-derivatives"
  acl  = "private"
  tags = "${local.common_tags}"

  cors_rule {
    allowed_origins = ["*.northwestern.edu"]
    allowed_methods = ["GET"]
    max_age_seconds = "3000"
    allowed_headers = ["Authorization", "Access-Control-Allow-Origin"]
  }
}

resource "aws_s3_bucket" "this_preservation" {
  #  bucket = "${local.namespace}-avr-preservation"
  acl  = "private"
  tags = "${local.common_tags}"
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
      "${aws_s3_bucket.this_masterfiles.arn}",
      "${aws_s3_bucket.this_derivatives.arn}",
      "${aws_s3_bucket.this_preservation.arn}",
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
      "${aws_s3_bucket.this_masterfiles.arn}/*",
      "${aws_s3_bucket.this_derivatives.arn}/*",
      "${aws_s3_bucket.this_preservation.arn}/*",
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
    resources = ["${aws_sqs_queue.this_batch_queue.arn}"]
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
      JobClassName = "BatchIngestJob"
      Secret       = "${random_id.secret_key_base.hex}"
      QueueUrl     = "${aws_sqs_queue.this_batch_queue.id}"
    }
  }
}

resource "aws_lambda_permission" "allow_trigger" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${module.this_batch_ingest.function_arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.this_masterfiles.arn}"
}

resource "aws_s3_bucket_notification" "batch_ingest_notification" {
  bucket = "${aws_s3_bucket.this_masterfiles.id}"

  lambda_function {
    lambda_function_arn = "${module.this_batch_ingest.function_arn}"
    filter_prefix       = "dropbox/"
    filter_suffix       = ".xls"

    events = [
      "s3:ObjectCreated:Put",
      "s3:ObjectCreated:Post",
      "s3:ObjectCreated:CompleteMultipartUpload",
    ]
  }

  lambda_function {
    lambda_function_arn = "${module.this_batch_ingest.function_arn}"
    filter_prefix       = "dropbox/"
    filter_suffix       = ".xlsx"

    events = [
      "s3:ObjectCreated:Put",
      "s3:ObjectCreated:Post",
      "s3:ObjectCreated:CompleteMultipartUpload",
    ]
  }
}

data "null_data_source" "ssm_parameters" {
  inputs = "${map(
    "domain/host",               "${local.domain_host}",
    "dropbox/path",              "s3://${aws_s3_bucket.this_masterfiles.id}/dropbox/",
    "dropbox/upload_uri",        "s3://${aws_s3_bucket.this_masterfiles.id}/dropbox/",
    "email/comments",            "${local.email["comments"]}",
    "email/notification",        "${local.email["notification"]}",
    "email/support",             "${local.email["support"]}",
    "encoding/pipeline",         "${aws_elastictranscoder_pipeline.this_pipeline.id}",
    "encoding/sns_topic",        "${aws_sns_topic.this_transcode_notification.arn}",
    "initial_user",              "${local.initial_user}",
    "solr/url",                  "${data.terraform_remote_state.stack.index_endpoint}avr",
    "streaming/http_base",       "http${length(data.aws_acm_certificate.ssl_certificate.*.arn) == 0 ? "" : "s"}://${coalesce(local.streaming_hostname, aws_route53_record.this_cloudfront.fqdn)}/",
    "zookeeper/connection_str",  "${data.terraform_remote_state.stack.zookeeper_address}:2181/configs"
  )}"
}

resource "aws_ssm_parameter" "this_config_setting" {
  count     = 12
  name      = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/Settings/${element(keys(data.null_data_source.ssm_parameters.outputs), count.index)}"
  type      = "String"
  value     = "${lookup(data.null_data_source.ssm_parameters.outputs, element(keys(data.null_data_source.ssm_parameters.outputs), count.index))}"
  overwrite = true
}
