data "archive_file" "cantaloupe_source" {
  type        = "zip"
  source_dir  = "${path.module}/applications/cantaloupe"
  output_path = "${path.module}/build/cantaloupe.zip"
}

resource "aws_s3_bucket_object" "cantaloupe_source" {
  bucket = "${aws_s3_bucket.app_sources.id}"
  key    = "cantaloupe.zip"
  source = "${path.module}/build/cantaloupe.zip"
  etag   = "${data.archive_file.cantaloupe_source.output_md5}"
}

resource "aws_s3_bucket" "pyramid_tiff_bucket" {
  bucket = "${local.namespace}-pyramids"
  acl    = "private"
  tags   = "${local.common_tags}"
}

resource "aws_iam_user" "pyramid_tiff_bucket_user" {
  name = "${local.namespace}-cantaloupe"
  path = "/system/"
}

resource "aws_iam_access_key" "pyramid_tiff_bucket_access_key" {
  user = "${aws_iam_user.pyramid_tiff_bucket_user.name}"
}

data "aws_iam_policy_document" "pyramid_tiff_bucket_access" {
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
    resources = ["${aws_s3_bucket.pyramid_tiff_bucket.arn}"]
  }

  statement {
    effect    = "Allow"
    actions   = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["${aws_s3_bucket.pyramid_tiff_bucket.arn}/*"]
  }
}

resource "aws_iam_user_policy" "pyramid_tiff_bucket_policy" {
  name   = "${local.namespace}-cantaloupe-s3-bucket-access"
  user   = "${aws_iam_user.pyramid_tiff_bucket_user.name}"
  policy = "${data.aws_iam_policy_document.pyramid_tiff_bucket_access.json}"
}

resource "aws_elastic_beanstalk_application" "cantaloupe" {
  name = "${local.namespace}-cantaloupe"
}

resource "aws_elastic_beanstalk_application_version" "cantaloupe" {
  name        = "cantaloupe-${data.archive_file.cantaloupe_source.output_md5}"
  application = "${aws_elastic_beanstalk_application.cantaloupe.name}"
  description = "application version created by terraform"
  bucket      = "${aws_s3_bucket.app_sources.id}"
  key         = "${aws_s3_bucket_object.cantaloupe_source.id}"
}

module "cantaloupe_environment" {
  source = "../beanstalk"

  app                    = "${aws_elastic_beanstalk_application.cantaloupe.name}"
  version_label          = "${aws_elastic_beanstalk_application_version.cantaloupe.name}"
  namespace              = "${var.stack_name}"
  name                   = "cantaloupe"
  stage                  = "${var.environment}"
  solution_stack_name    = "${data.aws_elastic_beanstalk_solution_stack.multi_docker.name}"
  vpc_id                 = "${module.vpc.vpc_id}"
  private_subnets        = "${module.vpc.private_subnets}"
  public_subnets         = "${module.vpc.public_subnets}"
  instance_port          = "8182"
  healthcheck_url        = "/iiif/2"
  keypair                = "${var.ec2_keyname}"
  instance_type          = "t2.medium"
  autoscale_min          = 1
  autoscale_max          = 2
  health_check_threshold = "Severe"
  tags                   = "${local.common_tags}"

  env_vars = {
    TIFF_BUCKET       = "${aws_s3_bucket.pyramid_tiff_bucket.id}",
    AWS_ACCESS_KEY_ID = "${aws_iam_access_key.pyramid_tiff_bucket_access_key.id}",
    AWS_SECRET_KEY    = "${aws_iam_access_key.pyramid_tiff_bucket_access_key.secret}"
  }
}

resource "aws_route53_record" "cantaloupe" {
  zone_id = "${module.dns.public_zone_id}"
  name    = "cantaloupe.${local.public_zone_name}"
  type    = "A"

  alias {
    name                   = "${module.cantaloupe_environment.elb_dns_name}"
    zone_id                = "${module.cantaloupe_environment.elb_zone_id}"
    evaluate_target_health = true
  }
}
