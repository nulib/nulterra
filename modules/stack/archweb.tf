resource "aws_iam_user" "archweb_bucket_user" {
  name = "${local.namespace}-archweb"
  path = "/system/"
}

resource "aws_iam_access_key" "archweb_bucket_access_key" {
  user = "${aws_iam_user.archweb_bucket_user.name}"
}

resource "aws_elastic_beanstalk_application" "archweb" {
  name = "${local.namespace}-archweb"
}

module "archweb_environment" {
  source                 = "../beanstalk"
  app                    = "${aws_elastic_beanstalk_application.archweb.name}"
  namespace              = "${var.stack_name}"
  name                   = "archweb"
  stage                  = "${var.environment}"
  solution_stack_name    = "${data.aws_elastic_beanstalk_solution_stack.multi_docker.name}"
  vpc_id                 = "${module.vpc.vpc_id}"
  private_subnets        = "${module.vpc.private_subnets}"
  public_subnets         = "${module.vpc.public_subnets}"
  loadbalancer_scheme    = "internal"
  instance_port          = "80"
  keypair                = "${var.ec2_keyname}"
  instance_type          = "t2.medium"
  autoscale_min          = "2"
  autoscale_max          = "7"
  health_check_threshold = "Severe"
  tags                   = "${local.common_tags}"
}

resource "aws_route53_record" "archweb" {
  zone_id = "${module.dns.private_zone_id}"
  name    = "archweb.${local.private_zone_name}"
  ttl     = "300"
  type    = "A"
}
