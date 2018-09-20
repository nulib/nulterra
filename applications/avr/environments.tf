locals {
  database_url  = "postgresql://${local.app_name}:${module.this_db.password}@${data.terraform_remote_state.stack.db_address}:${data.terraform_remote_state.stack.db_port}/${local.app_name}?pool=50"
  mount_volumes = ""
}

data "aws_iam_policy_document" "this_instance_pipeline_access_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:Get*",
      "s3:Put*",
      "s3:*MultipartUpload*",
      "s3:Delete*",
    ]

    resources = [
      "${aws_s3_bucket.this_masterfiles.arn}",
      "${aws_s3_bucket.this_derivatives.arn}",
      "${aws_s3_bucket.this_masterfiles.arn}/*",
      "${aws_s3_bucket.this_derivatives.arn}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "elastictranscoder:List*",
      "elastictranscoder:Read*",
    ]

    resources = [
      "${aws_elastictranscoder_pipeline.this_pipeline.arn}",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "elastictranscoder:CreatePreset",
      "elastictranscoder:ListPresets",
      "elastictranscoder:ReadPreset",
      "elastictranscoder:ListJobs",
      "elastictranscoder:CreateJob",
      "elastictranscoder:ReadJob",
      "elastictranscoder:CancelJob",
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ses:Send*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "this_instance_pipeline_access_policy" {
  name   = "${local.namespace}-${local.app_name}-instance-pipeline-access-policy"
  policy = "${data.aws_iam_policy_document.this_instance_pipeline_access_policy.json}"
}

module "webapp" {
  source              = "./environment"
  app_name            = "${aws_elastic_beanstalk_application.this.name}"
  app_version         = "${aws_elastic_beanstalk_application_version.this.name}"
  autoscale_min       = 1
  autoscale_max       = 2
  bucket_policy_arn   = "${aws_iam_policy.this_bucket_policy.arn}"
  database_url        = "${local.database_url}"
  honeybadger_api_key = "${var.honeybadger_api_key}"
  lti_key             = "${var.lti_key}"
  lti_secret          = "${var.lti_secret}"
  mount_volumes       = "${local.mount_volumes}"
  name                = "${local.app_name}"
  namespace           = "${local.namespace}"
  preservation_bucket = "${aws_s3_bucket.this_preservation.id}"
  ssl_certificate     = "${join("", data.aws_acm_certificate.ssl_certificate.*.arn)}"
  worker_queue        = "${aws_sqs_queue.this_ui_queue.name}"
  worker_queue_url    = "${aws_sqs_queue.this_ui_queue.id}"
  secret_key_base     = "${random_id.secret_key_base.hex}"
  tags                = "${local.common_tags}"
  tier                = "WebServer"
  tier_name           = "webapp"
  stack_state         = "${local.stack_state}"
}

module "worker" {
  source              = "./environment"
  app_name            = "${aws_elastic_beanstalk_application.this.name}"
  app_version         = "${aws_elastic_beanstalk_application_version.this.name}"
  autoscale_min       = 1
  autoscale_max       = 2
  bucket_policy_arn   = "${aws_iam_policy.this_bucket_policy.arn}"
  database_url        = "${local.database_url}"
  honeybadger_api_key = "${var.honeybadger_api_key}"
  lti_key             = "${var.lti_key}"
  lti_secret          = "${var.lti_secret}"
  mount_volumes       = "${local.mount_volumes}"
  name                = "${local.app_name}"
  namespace           = "${local.namespace}"
  preservation_bucket = "${aws_s3_bucket.this_preservation.id}"
  worker_queue        = "${aws_sqs_queue.this_ui_queue.name}"
  worker_queue_url    = "${aws_sqs_queue.this_ui_queue.id}"
  secret_key_base     = "${random_id.secret_key_base.hex}"
  tags                = "${local.common_tags}"
  tier                = "Worker"
  tier_name           = "ui-worker"
  stack_state         = "${local.stack_state}"
}

module "batch_worker" {
  source              = "./environment"
  app_name            = "${aws_elastic_beanstalk_application.this.name}"
  app_version         = "${aws_elastic_beanstalk_application_version.this.name}"
  autoscale_min       = 1
  autoscale_max       = 2
  bucket_policy_arn   = "${aws_iam_policy.this_bucket_policy.arn}"
  database_url        = "${local.database_url}"
  honeybadger_api_key = "${var.honeybadger_api_key}"
  lti_key             = "${var.lti_key}"
  lti_secret          = "${var.lti_secret}"
  mount_volumes       = "${local.mount_volumes}"
  name                = "${local.app_name}"
  namespace           = "${local.namespace}"
  preservation_bucket = "${aws_s3_bucket.this_preservation.id}"
  worker_queue        = "${aws_sqs_queue.this_batch_queue.name}"
  worker_queue_url    = "${aws_sqs_queue.this_batch_queue.id}"
  secret_key_base     = "${random_id.secret_key_base.hex}"
  tags                = "${local.common_tags}"
  tier                = "Worker"
  tier_name           = "batch-worker"
  stack_state         = "${local.stack_state}"
}

resource "aws_iam_role_policy_attachment" "webapp_pipeline_access" {
  role       = "${module.webapp.instance_profile_role_name}"
  policy_arn = "${aws_iam_policy.this_instance_pipeline_access_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "worker_pipeline_access" {
  role       = "${module.worker.instance_profile_role_name}"
  policy_arn = "${aws_iam_policy.this_instance_pipeline_access_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "batch_worker_pipeline_access" {
  role       = "${module.batch_worker.instance_profile_role_name}"
  policy_arn = "${aws_iam_policy.this_instance_pipeline_access_policy.arn}"
}
