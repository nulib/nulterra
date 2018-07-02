variable "app_name" {
  type = "string"
}

variable "app_version" {
  type = "string"
}

variable "autoscale_min" {
  type = "string"
}

variable "autoscale_max" {
  type = "string"
}

variable "bucket_policy_arn" {
  type = "string"
}

variable "database_url" {
  type = "string"
}

variable "lti_key" {
  type = "string"
}

variable "lti_secret" {
  type = "string"
}

variable "mount_volumes" {
  type = "string"
}

variable "name" {
  type = "string"
}

variable "namespace" {
  type = "string"
}

variable "preservation_bucket" {
  type = "string"
}

variable "secret_key_base" {
  type = "string"
}

variable "stack_state" {
  type = "map"
}

variable "tags" {
  type = "map"
}

variable "tier" {
  type = "string"
}

variable "tier_name" {
  type = "string"
}

variable "worker_queue" {
  type = "string"
}

variable "worker_queue_url" {
  type = "string"
}

variable "ssl_certificate" {
  type    = "string"
  default = ""
}

data "terraform_remote_state" "stack" {
  backend = "s3"

  config {
    bucket = "${var.stack_state["bucket"]}"
    key    = "${var.stack_state["key"]}"
    region = "${var.stack_state["region"]}"
  }
}

data "aws_elastic_beanstalk_solution_stack" "multi_docker" {
  most_recent = true
  name_regex  = "^64bit Amazon Linux (.*) Multi-container Docker (.*)$"
}

resource "aws_security_group_rule" "allow_avrs_fcrepo_access" {
  security_group_id        = "${data.terraform_remote_state.stack.security_groups.fcrepo}"
  type                     = "ingress"
  from_port                = "80"
  to_port                  = "80"
  protocol                 = "tcp"
  source_security_group_id = "${module.avr_environment.security_group_id}"
}

resource "aws_security_group_rule" "allow_avrs_postgres_access" {
  security_group_id        = "${data.terraform_remote_state.stack.security_groups.db}"
  type                     = "ingress"
  from_port                = "${data.terraform_remote_state.stack.db_port}"
  to_port                  = "${data.terraform_remote_state.stack.db_port}"
  protocol                 = "tcp"
  source_security_group_id = "${module.avr_environment.security_group_id}"
}

resource "aws_security_group_rule" "allow_avrs_redis_access" {
  security_group_id        = "${data.terraform_remote_state.stack.security_groups.cache}"
  type                     = "ingress"
  from_port                = "${data.terraform_remote_state.stack.cache_port}"
  to_port                  = "${data.terraform_remote_state.stack.cache_port}"
  protocol                 = "tcp"
  source_security_group_id = "${module.avr_environment.security_group_id}"
}

resource "aws_iam_role_policy_attachment" "avr_bucket_role_access" {
  role       = "${module.avr_environment.ec2_instance_profile_role_name}"
  policy_arn = "${var.bucket_policy_arn}"
}

resource "aws_security_group_rule" "allow_zk_avr_access" {
  security_group_id        = "${data.terraform_remote_state.stack.security_groups.zookeeper}"
  type                     = "ingress"
  from_port                = "2181"
  to_port                  = "2181"
  protocol                 = "tcp"
  source_security_group_id = "${module.avr_environment.security_group_id}"
}

module "avr_environment" {
  source                       = "../../../modules/beanstalk"
  app                          = "${var.app_name}"
  version_label                = "${var.app_version}"
  namespace                    = "${data.terraform_remote_state.stack.stack_name}"
  name                         = "${var.name}-${var.tier_name}"
  tier                         = "${var.tier}"
  stage                        = "${data.terraform_remote_state.stack.environment}"
  solution_stack_name          = "${data.aws_elastic_beanstalk_solution_stack.multi_docker.name}"
  vpc_id                       = "${data.terraform_remote_state.stack.vpc_id}"
  private_subnets              = "${data.terraform_remote_state.stack.private_subnets}"
  public_subnets               = "${data.terraform_remote_state.stack.public_subnets}"
  http_listener_enabled        = "${lower(var.tier) == "worker" ? "false" : "true" }"
  loadbalancer_certificate_arn = "${var.ssl_certificate}"
  loadbalancer_scheme          = "${lower(var.tier) == "worker" ? "" : "public" }"
  instance_port                = "80"
  healthcheck_url              = "/"
  keypair                      = "${data.terraform_remote_state.stack.ec2_keyname}"
  instance_type                = "t2.medium"
  autoscale_min                = "${var.autoscale_min}"
  autoscale_max                = "${var.autoscale_max}"
  health_check_threshold       = "Ok"
  sqsd_worker_queue_url        = "${var.worker_queue_url}"
  tags                         = "${var.tags}"

  env_vars = {
    AWS_REGION                                 = "${data.terraform_remote_state.stack.aws_region}"
    DATABASE_URL                               = "${var.database_url}"
    FEDORA_BASE_PATH                           = "/${var.name}"
    FEDORA_URL                                 = "${data.terraform_remote_state.stack.repo_endpoint}"
    LTI_AUTH_KEY                               = "${var.lti_key}"
    LTI_AUTH_SECRET                            = "${var.lti_secret}"
    MOUNT_GID                                  = "1000"
    MOUNT_VOLUMES                              = "${var.mount_volumes}"
    PROCESS_ACTIVE_ELASTIC_JOBS                = "${lower(var.tier) == "worker" ? "true" : "false" }"
    RACK_ENV                                   = "production"
    REDIS_HOST                                 = "${data.terraform_remote_state.stack.cache_address}"
    REDIS_PORT                                 = "${data.terraform_remote_state.stack.cache_port}"
    REDIS_URL                                  = "redis://${data.terraform_remote_state.stack.cache_address}:${data.terraform_remote_state.stack.cache_port}/"
    SECRET_KEY_BASE                            = "${var.secret_key_base}"
    SETTINGS__ACTIVE_JOB__QUEUE_URL            = "${var.worker_queue}"
    SETTINGS__ACTIVE_JOB__QUEUES__INGEST       = "${var.worker_queue}"
    SETTINGS__MASTER_FILE_MANAGEMENT__PATH     = "s3://${var.preservation_bucket}/avalon-masterfiles/"
    SETTINGS__MASTER_FILE_MANAGEMENT__STRATEGY = "MOVE"
    SETTINGS__REDIS__HOST                      = "${data.terraform_remote_state.stack.cache_address}"
    SETTINGS__REDIS__PORT                      = "${data.terraform_remote_state.stack.cache_port}"
    SETTINGS__SOLRCLOUD                        = "true"
    SETTINGS__WORKER                           = "${lower(var.tier) == "worker" ? "true" : "false" }"
    SOLR_URL                                   = "${data.terraform_remote_state.stack.index_endpoint}${var.name}"
    SSM_PARAM_PATH                             = "/${data.terraform_remote_state.stack.stack_name}-${var.name}"
    STACK_NAME                                 = "${var.name}"
    STACK_NAMESPACE                            = "${var.namespace}"
    STACK_TIER                                 = "${var.tier_name}"
  }
}

resource "aws_route53_record" "avr" {
  count   = "${lower(var.tier) == "worker" ? 0 : 1 }"
  zone_id = "${data.terraform_remote_state.stack.public_zone_id}"
  name    = "${var.name}.${data.terraform_remote_state.stack.stack_name}.${data.terraform_remote_state.stack.hosted_zone_name}"
  type    = "A"

  alias {
    name                   = "${module.avr_environment.elb_dns_name}"
    zone_id                = "${module.avr_environment.elb_zone_id}"
    evaluate_target_health = "true"
  }
}

output "endpoint" {
  value = "${aws_route53_record.avr.*.name}"
}

output "instance_profile_role_name" {
  value = "${module.avr_environment.ec2_instance_profile_role_name}"
}

output "security_group_id" {
  value = "${module.avr_environment.security_group_id}"
}
