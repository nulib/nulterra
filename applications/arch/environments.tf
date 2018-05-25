locals {
  database_url  = "postgresql://${local.app_name}:${module.archdb.password}@${data.terraform_remote_state.stack.db_address}:${data.terraform_remote_state.stack.db_port}/${local.app_name}"
  mount_volumes = "/var/app/arch-derivatives=${module.arch_derivative_volume.dns_name}:/var/app/arch-working=${module.arch_working_volume.dns_name}"
}

module "webapp" {
  source            = "./environment"
  app_name          = "${aws_elastic_beanstalk_application.arch.name}"
  app_version       = "${aws_elastic_beanstalk_application_version.arch.name}"
  autoscale_min     = 1
  autoscale_max     = 2
  bucket_policy_arn = "${aws_iam_policy.arch_bucket_policy.arn}"
  database_url      = "${local.database_url}"
  mount_volumes     = "${local.mount_volumes}"
  name              = "${local.app_name}"
  worker_queue      = "${aws_sqs_queue.arch_ui_fifo_queue.name}"
  worker_queue_url  = "${aws_sqs_queue.arch_ui_fifo_queue.id}"
  secret_key_base   = "${random_id.secret_key_base.hex}"
  tags              = "${local.common_tags}"
  tier              = "WebServer"
  tier_name         = "webapp"
  stack_state       = "${local.stack_state}"
}

module "worker" {
  source            = "./environment"
  app_name          = "${aws_elastic_beanstalk_application.arch.name}"
  app_version       = "${aws_elastic_beanstalk_application_version.arch.name}"
  autoscale_min     = 1
  autoscale_max     = 2
  bucket_policy_arn = "${aws_iam_policy.arch_bucket_policy.arn}"
  database_url      = "${local.database_url}"
  mount_volumes     = "${local.mount_volumes}"
  name              = "${local.app_name}"
  worker_queue      = "${aws_sqs_queue.arch_ui_fifo_queue.name}"
  worker_queue_url  = "${aws_sqs_queue.arch_ui_fifo_queue.id}"
  secret_key_base   = "${random_id.secret_key_base.hex}"
  tags              = "${local.common_tags}"
  tier              = "Worker"
  tier_name         = "ui-worker"
  stack_state       = "${local.stack_state}"
}