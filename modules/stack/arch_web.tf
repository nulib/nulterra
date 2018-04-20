resource "aws_iam_user" "arch_web_bucket_user" {
  name = "${local.namespace}-arch_web"
  path = "/system/"
}

resource "aws_iam_access_key" "arch_web_bucket_access_key" {
  user = "${aws_iam_user.arch_web_bucket_user.name}"
}

resource "aws_elastic_beanstalk_application" "arch_web" {
  name = "${local.namespace}-arch_web"
}

module "arch_web_environment" {
  source = "../beanstalk"
  app                    = "{aws_elastic_beanstalk_application.arch_web.name}".
  version_label          = "{aws_elastic_beanstalk_application_version.arch_web.name}".
  namespace              = "{var.stack_name}"
  name                   = "arch_web"
  stage                  = "{var.environment}"
  solution_stack_name    = "{data.aws_elastic_beanstalk_solution_stack.multi_docker.name}"
  vpc_id                 = "{module.vpc.vpc_id}"
  private_subnets        = "{module.vpc.private_subnets}"
  public_subnets         = "{module.vpc.public_subnets}"
  loadbalancer_scheme    = "internal"
  instance_port          = "80"
  healthceck_url         = "arch"
  keypair                = "${var.ce2_keyname}"
  instance_type          = "t2.medium"
  autoscale_min          = "2"
  autoscale_max          = "7"
  health_check_threshold = "Severe"
  tags                   = "${local.common_tags}"
}

resource "aws_route53_record" "arch_web" {
  zone_id = "${module.dns.private_zone_id}"
  name    = "arch_web.${local.private_zone_name}"
  type    = "A"
}
