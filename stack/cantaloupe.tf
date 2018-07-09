resource "aws_s3_bucket" "pyramid_tiff_bucket" {
  bucket = "${local.namespace}-pyramid-tiffs"
  acl    = "private"
  tags   = "${local.common_tags}"
}

data "aws_iam_policy_document" "pyramid_tiff_bucket_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["arn:aws:s3:::*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]

    resources = ["${aws_s3_bucket.pyramid_tiff_bucket.arn}"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]

    resources = ["${aws_s3_bucket.pyramid_tiff_bucket.arn}/*"]
  }
}

resource "aws_iam_role_policy" "pyramid_tiff_bucket_policy" {
  name   = "${local.namespace}-cantaloupe-s3-bucket-access"
  role   = "${module.cantaloupe_service.container_role}"
  policy = "${data.aws_iam_policy_document.pyramid_tiff_bucket_access.json}"
}

data "template_file" "cantaloupe_task_definition" {
  template = "${file("${path.module}/applications/cantaloupe/service.json.tpl")}"

  vars = {
    aws_region        = "${var.aws_region}"
    tiff_bucket       = "${aws_s3_bucket.pyramid_tiff_bucket.id}"
    namespace         = "${local.namespace}"
  }
}

module "cantaloupe_service" {
  source = "../modules/fargate"

  container_definitions = "${data.template_file.cantaloupe_task_definition.rendered}"
  container_name        = "cantaloupe-app"
  cpu                   = "1024"
  family                = "cantaloupe"
  instance_port         = "8182"
  memory                = "8192"
  namespace             = "${local.namespace}"
  internal              = "false"
  private_subnets       = ["${module.vpc.private_subnets}"]
  public_subnets        = ["${module.vpc.public_subnets}"]
  security_groups       = ["${module.vpc.default_security_group_id}"]
  tags                  = "${local.common_tags}"
  vpc_id                = "${module.vpc.vpc_id}"
}

resource "aws_security_group_rule" "allow_all_access_to_cantaloupe" {
  security_group_id = "${module.cantaloupe_service.lb_security_group}"
  type              = "ingress"
  from_port         = "80"
  to_port           = "80"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_cloudfront_distribution" "cantaloupe" {
  count            = "${local.enable_iiif_cloudfront ? 1 : 0}"
  enabled          = true
  is_ipv6_enabled  = true
  retain_on_delete = true

  origin {
    domain_name = "${aws_route53_record.cantaloupe.name}"
    origin_id   = "cantaloupe-elb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "cantaloupe-elb"
    viewer_protocol_policy = "allow-all"

    forwarded_values {
      cookies {
        forward = "none"
      }

      query_string = false
      headers      = ["Origin"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_route53_record" "cantaloupe" {
  zone_id = "${module.dns.public_zone_id}"
  name    = "cantaloupe.${local.public_zone_name}"
  type    = "A"

  alias {
    name                   = "${module.cantaloupe_service.lb_dns_name}"
    zone_id                = "${module.cantaloupe_service.lb_zone_id}"
    evaluate_target_health = true
  }
}
