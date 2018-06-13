locals {
  database_url  = "postgresql://${local.app_name}:${module.donutdb.password}@${data.terraform_remote_state.stack.db_address}:${data.terraform_remote_state.stack.db_port}/${local.app_name}"
  mount_volumes = "/var/app/donut-derivatives=${module.donut_derivative_volume.dns_name}:/var/app/donut-working=${module.donut_working_volume.dns_name}"
}

module "webapp" {
  source            = "./environment"
  app_name          = "${aws_elastic_beanstalk_application.donut.name}"
  app_version       = "${aws_elastic_beanstalk_application_version.donut.name}"
  autoscale_min     = 1
  autoscale_max     = 2
  bucket_policy_arn = "${aws_iam_policy.donut_bucket_policy.arn}"
  database_url      = "${local.database_url}"
  mount_volumes     = "${local.mount_volumes}"
  name              = "${local.app_name}"
  namespace         = "${local.namespace}"
  worker_queue      = "${aws_sqs_queue.donut_ui_fifo_queue.name}"
  worker_queue_url  = "${aws_sqs_queue.donut_ui_fifo_queue.id}"
  secret_key_base   = "${random_id.secret_key_base.hex}"
  tags              = "${local.common_tags}"
  tier              = "WebServer"
  tier_name         = "webapp"
  stack_state       = "${local.stack_state}"
}

module "worker" {
  source            = "./environment"
  app_name          = "${aws_elastic_beanstalk_application.donut.name}"
  app_version       = "${aws_elastic_beanstalk_application_version.donut.name}"
  autoscale_min     = 1
  autoscale_max     = 2
  bucket_policy_arn = "${aws_iam_policy.donut_bucket_policy.arn}"
  database_url      = "${local.database_url}"
  mount_volumes     = "${local.mount_volumes}"
  name              = "${local.app_name}"
  namespace         = "${local.namespace}"
  worker_queue      = "${aws_sqs_queue.donut_ui_fifo_queue.name}"
  worker_queue_url  = "${aws_sqs_queue.donut_ui_fifo_queue.id}"
  secret_key_base   = "${random_id.secret_key_base.hex}"
  tags              = "${local.common_tags}"
  tier              = "Worker"
  tier_name         = "ui-worker"
  stack_state       = "${local.stack_state}"
}

module "batch_worker" {
  source            = "./environment"
  app_name          = "${aws_elastic_beanstalk_application.donut.name}"
  app_version       = "${aws_elastic_beanstalk_application_version.donut.name}"
  autoscale_min     = 1
  autoscale_max     = 2
  bucket_policy_arn = "${aws_iam_policy.donut_bucket_policy.arn}"
  database_url      = "${local.database_url}"
  mount_volumes     = "${local.mount_volumes}"
  name              = "${local.app_name}"
  namespace         = "${local.namespace}"
  worker_queue      = "${aws_sqs_queue.donut_batch_fifo_queue.name}"
  worker_queue_url  = "${aws_sqs_queue.donut_batch_fifo_queue.id}"
  secret_key_base   = "${random_id.secret_key_base.hex}"
  tags              = "${local.common_tags}"
  tier              = "Worker"
  tier_name         = "batch-worker"
  stack_state       = "${local.stack_state}"
}
