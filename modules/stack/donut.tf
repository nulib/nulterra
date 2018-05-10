module "donut_derivative_space_volume" {
  source  = "cloudposse/efs/aws"
  version = "0.3.3"

  namespace          = "${var.stack_name}"
  stage              = "donut"
  name               = "derivative_space"
  aws_region         = "${var.aws_region}"
  vpc_id             = "${module.vpc.vpc_id}"
  subnets            = "${module.vpc.private_subnets}"
  availability_zones = ["${var.azs}"]
  security_groups    = ["${module.donut_environment.security_group_id}"]

  zone_id = "${module.dns.private_zone_id}"

  tags = "${local.common_tags}"
}

module "donut_working_space_volume" {
  source  = "cloudposse/efs/aws"
  version = "0.3.3"

  namespace          = "${var.stack_name}"
  stage              = "donut"
  name               = "working_space"
  aws_region         = "${var.aws_region}"
  vpc_id             = "${module.vpc.vpc_id}"
  subnets            = "${module.vpc.private_subnets}"
  availability_zones = ["${var.azs}"]
  security_groups    = ["${module.donut_environment.security_group_id}"]

  zone_id = "${module.dns.private_zone_id}"

  tags = "${local.common_tags}"
}

resource "aws_iam_user" "donut_bucket_user" {
  name = "${local.namespace}-donut"
  path = "/system/"
}

resource "aws_iam_access_key" "donut_bucket_access_key" {
  user = "${aws_iam_user.donut_bucket_user.name}"
}

resource "aws_elastic_beanstalk_application" "donut" {
  name = "${local.namespace}-donut"
}

resource "aws_elastic_beanstalk_application_version" "donut" {
  description = "application version created by terraform"
  bucket      = "${aws_s3_bucket.app_sources.id}"
  application = "donut"
  key = "donut"
  name = "somename"
}

module "donut_environment" {
  source                 = "../beanstalk"
  app                    = "${aws_elastic_beanstalk_application.donut.name}"
  namespace              = "${var.stack_name}"
  name                   = "donut"
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

resource "aws_cloudfront_distribution" "donut" {
  count            = "${var.enable_iiif_cloudfront ? 1 : 0}"
  enabled          = true
  is_ipv6_enabled  = true
  retain_on_delete = true

  origin {
    domain_name = "${aws_route53_record.donut.name}"
    origin_id   = "donut-elb"

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
    target_origin_id       = "donut-elb"
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


resource "aws_route53_record" "donut" {
  zone_id = "${module.dns.private_zone_id}"
  name    = "donut.${local.private_zone_name}"
  type    = "A"
  alias { 
    name                   = "${module.donut_environment.elb_dns_name}"
    zone_id                = "${module.donut_environment.elb_zone_id}"
    evaluate_target_health = "true"
  }
}
