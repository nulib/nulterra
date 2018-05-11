resource "aws_security_group_rule" "allow_donut_postgres_access" {
  type      = "ingress"
  from_port = "${data.terraform_remote_state.stack.db_port}"
  to_port   = "${data.terraform_remote_state.stack.db_port}"
  protocol  = "tcp"

  security_group_id = "${data.terraform_remote_state.stack.db_security_group_id}"

  source_security_group_id = "${module.donut_webapp_environment.security_group_id}"
}

module "donut_webapp_environment" {
  source                 = "../../modules/beanstalk"
  app                    = "${aws_elastic_beanstalk_application.donut.name}"
  version_label          = "${aws_elastic_beanstalk_application_version.donut.name}"
  namespace              = "${data.terraform_remote_state.stack.stack_name}"
  name                   = "${local.app_name}"
  stage                  = "${data.terraform_remote_state.stack.environment}"
  solution_stack_name    = "${data.aws_elastic_beanstalk_solution_stack.multi_docker.name}"
  vpc_id                 = "${data.terraform_remote_state.stack.vpc_id}"
  private_subnets        = "${data.terraform_remote_state.stack.private_subnets}"
  public_subnets         = "${data.terraform_remote_state.stack.public_subnets}"
  loadbalancer_scheme    = "internal"
  instance_port          = "80"
  keypair                = "${data.terraform_remote_state.stack.ec2_keyname}"
  instance_type          = "t2.medium"
  autoscale_min          = "1"
  autoscale_max          = "2"
  health_check_threshold = "Severe"
  tags                   = "${local.common_tags}"

  env_vars = {
    DATABASE_URL                 = "postgresql://${local.app_name}:${module.donutdb.password}@${data.terraform_remote_state.stack.db_address}:${data.terraform_remote_state.stack.db_port}/${local.app_name}"
    FEDORA_BASE_PATH             = "/${local.app_name}"
    FEDORA_URL                   = "${data.terraform_remote_state.stack.repo_endpoint}"
    MOUNT_VOLUMES                = "/var/app/donut-derivatives=${module.donut_derivative_volume.dns_name}:/var/app/donut-working=${module.donut_working_volume.dns_name}",
    PROCESS_ACTIVE_ELASTIC_JOBS  = "false"
    RACK_ENV                     = "production"
    REDIS_HOST                   = "${data.terraform_remote_state.stack.cache_address}"
    REDIS_PORT                   = "${data.terraform_remote_state.stack.cache_port}"
    SECRET_KEY_BASE              = "${random_id.secret_key_base.hex}"
    SETTINGS__WORKER             = "false"
    SOLR_URL                     = "${data.terraform_remote_state.stack.index_endpoint}${local.app_name}"
    SSM_PARAM_PATH               = "/${data.terraform_remote_state.stack.stack_name}-${local.app_name}"
    STACK_NAME                   = "${local.app_name}"
  }
}

resource "aws_route53_record" "donut" {
  zone_id = "${data.terraform_remote_state.stack.private_zone_id}"
  name    = "donut.${local.private_zone_name}"
  type    = "A"
  alias {
    name                   = "${module.donut_webapp_environment.elb_dns_name}"
    zone_id                = "${module.donut_webapp_environment.elb_zone_id}"
    evaluate_target_health = "true"
  }
}
