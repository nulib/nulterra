locals {
  frontend_dns_name = "dc.${local.public_zone_name}"
  frontend_aliases  = "${concat(list(local.frontend_dns_name), var.frontend_dns_names)}"
}

data "aws_acm_certificate" "frontend_certificate" {
  count       = "${length(var.frontend_dns_names) == 0 ? 0 : 1}"
  domain      = "${local.frontend_dns_name}"
  most_recent = true
}

resource "aws_s3_bucket" "static_frontend_bucket" {
  bucket = "${local.frontend_dns_name}"
  acl    = "private"
  tags   = "${local.common_tags}"
}

resource "aws_ssm_parameter" "glaze_bucket_name" {
  name        = "/${var.stack_name}-glaze/s3_bucket"
  value       = "${aws_s3_bucket.static_frontend_bucket.id}"
  type        = "String"
  overwrite   = true
}

resource "aws_cloudfront_origin_access_identity" "frontend_origin_access_identity" {
  comment = "${local.namespace}-frontend"
}

data "aws_iam_policy_document" "frontend_bucket_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static_frontend_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.frontend_origin_access_identity.iam_arn}"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.static_frontend_bucket.arn}"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.frontend_origin_access_identity.iam_arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "allow_cloudfront_frontend_access" {
  bucket = "${aws_s3_bucket.static_frontend_bucket.id}"
  policy = "${data.aws_iam_policy_document.frontend_bucket_policy.json}"
}

resource "aws_cloudfront_distribution" "frontend" {
  origin {
    domain_name = "${aws_s3_bucket.static_frontend_bucket.bucket_domain_name}"
    origin_id   = "${local.namespace}-frontend-origin"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.frontend_origin_access_identity.cloudfront_access_identity_path}"
    }
  }

  enabled               = true
  is_ipv6_enabled       = true
  comment               = "Glaze"
  default_root_object   = "index.html"

  aliases = "${local.frontend_aliases}"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.namespace}-frontend-origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy    = "allow-all"
    min_ttl                   = 0
    default_ttl               = 3600
    max_ttl                   = 86400
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = "${length(data.aws_acm_certificate.frontend_certificate.*.arn) == 0 ? true : false}"
    acm_certificate_arn            = "${join("", data.aws_acm_certificate.frontend_certificate.*.arn)}"
    ssl_support_method             = "sni-only"
  }

  price_class   = "PriceClass_100"
  tags          = "${local.common_tags}"
}

resource "aws_route53_record" "frontend_dns" {
  zone_id = "${module.dns.public_zone_id}"
  name    = "${local.frontend_dns_name}"
  type    = "CNAME"
  ttl     = "900"
  records = ["${aws_cloudfront_distribution.frontend.domain_name}"]
}
