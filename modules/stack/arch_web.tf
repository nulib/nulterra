
resource "aws_iam_user" "arch_web_bucket_user" {
  name = "${local.namespace}-arch_web"
  path = "/system/"
}

resource "aws_iam_access_key" "arch_web_bucket_access_key" {
  user = "${aws_iam_user.arch_web_bucket_user.name}"
}

data "aws_iam_policy_document" "arch_web_bucket_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["arn:aws:s3:::*"]
  }

  statement {
    effect    = "Allow"
    actions   = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = ["${aws_s3_bucket.arch_web_bucket.arn}"]
  }

  statement {
    effect    = "Allow"
    actions   = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["${aws_s3_bucket.arch_web_bucket.arn}/*"]
  }
}

resource "aws_iam_user_policy" "arch_web_bucket_policy" {
  name   = "${local.namespace}-arch_web-s3-bucket-access"
  user   = "${aws_iam_user.arch_web_bucket_user.name}"
  policy = "${data.aws_iam_policy_document.arch_web_bucket_access.json}"
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
