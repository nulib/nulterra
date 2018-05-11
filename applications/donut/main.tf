locals {
  app_name = "donut"
}

data "aws_elastic_beanstalk_solution_stack" "multi_docker" {
  most_recent   = true
  name_regex    = "^64bit Amazon Linux (.*) Multi-container Docker (.*)$"
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
    "${module.donut_webapp_environment.security_group_id}"
  ]
#    "${module.donut_worker_environment.security_group_id}",
#    "${module.donut_ui_worker_environment.security_group_id}"

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
    "${module.donut_webapp_environment.security_group_id}"
  ]
#    "${module.donut_worker_environment.security_group_id}",
#    "${module.donut_ui_worker_environment.security_group_id}"

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
  key    = "${local.app_name}.zip"
  source = "${path.module}/build/${local.app_name}.zip"
  etag   = "${data.archive_file.donut_source.output_md5}"
}

resource "aws_elastic_beanstalk_application" "donut" {
  name = "${local.namespace}-${local.app_name}"
}

resource "aws_elastic_beanstalk_application_version" "donut" {
  description = "application version created by terraform"
  bucket      = "${data.terraform_remote_state.stack.application_source_bucket}"
  application = "${local.namespace}-${local.app_name}"
  key         = "${local.app_name}.zip"
  name        = "${random_pet.app_version_name.id}"
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

resource "aws_sqs_queue" "donut_fifo_deadletter_queue" {
  name                        = "${data.terraform_remote_state.stack.stack_name}-donut-ui-dead-letter-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  tags                        = "${local.common_tags}"
}

resource "aws_sqs_queue" "donut_fifo_queue" {
  name                        = "${data.terraform_remote_state.stack.stack_name}-donut-ui-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  delay_seconds               = 0
  visibility_timeout_seconds  = 3600
  redrive_policy              = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.donut_fifo_deadletter_queue.arn}\",\"maxReceiveCount\":5}"
  tags                        = "${local.common_tags}"
}

resource "aws_ssm_parameter" "active_job_queue_adapter" {
  name = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/active_job/queue_adapter"
  type = "String"
  value = "active_elastic_job"
}

resource "aws_ssm_parameter" "derivatives_path" {
  name = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/derivatives_path"
  type = "String"
  value = "/var/donut-derivatives"
}

resource "aws_ssm_parameter" "ffmpeg_path" {
  name = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/ffmpeg/path"
  type = "String"
  value = "/usr/local/bin/ffmpeg"
}

resource "aws_ssm_parameter" "fits_path" {
  name = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/fits/path"
  type = "String"
  value = "/usr/local/fits/fits.sh"
}

resource "aws_ssm_parameter" "groups_system_groups" {
  name = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/groups/system_groups"
  type = "String"
  value = "administrator,group_manager,manager"
}

resource "aws_ssm_parameter" "name" {
  name = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/name"
  type = "String"
  value = "${local.app_name}"
}

resource "aws_ssm_parameter" "upload_path" {
  name = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/upload_path"
  type = "String"
  value = "/var/donut-working/temp"
}

resource "aws_ssm_parameter" "working_path" {
  name = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}/working_path"
  type = "String"
  value = "/var/donut-working/work"
}
