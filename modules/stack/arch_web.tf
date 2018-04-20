
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

resource "aws_route53_record" "arch_web" {
  zone_id = "${module.dns.private_zone_id}"
  name    = "arch_web.${local.private_zone_name}"
  type    = "A"

  alias {
    name                   = "${module.fcrepo_environment.elb_dns_name}"
    zone_id                = "${module.fcrepo_environment.elb_zone_id}"
    evaluate_target_health = true
  }
}
