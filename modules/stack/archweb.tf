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

resource "aws_elastic_beanstalk_application_version" "archweb" {
  description = "application version created by terraform"
  bucket      = "${aws_s3_bucket.app_sources.id}"
  application = "archweb"
  key = "archweb"
  name = "somename"
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

resource "aws_cloudfront_distribution" "archweb" {
  count            = "${var.enable_archweb ? 1 : 0}"
  enabled          = true
  is_ipv6_enabled  = true
  retain_on_delete = true

  origin {
    domain_name = "${aws_route53_record.archweb.name}"
    origin_id   = "archweb-elb"

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
    target_origin_id       = "archweb-elb"
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


resource "aws_route53_record" "archweb" {
  zone_id = "${module.dns.private_zone_id}"
  name    = "archweb.${local.private_zone_name}"
  type    = "A"
  alias { 
    name                   = "${module.archweb_environment.elb_dns_name}"
    zone_id                = "${module.archweb_environment.elb_zone_id}"
    evaluate_target_health = "true"
  }
}
