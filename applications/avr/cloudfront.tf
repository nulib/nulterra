locals {
  stream_fqdn = "httpstream.${data.terraform_remote_state.stack.stack_name}.${data.terraform_remote_state.stack.hosted_zone_name}"
  streaming_aliases = "${compact(list(local.stream_fqdn, var.streaming_hostname))}"
}

resource "aws_cloudfront_origin_access_identity" "avr_origin_access_identity" {
  comment = "${local.namespace}-${local.app_name}"
}

data "aws_iam_policy_document" "derivative_bucket_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.avr_derivatives.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.avr_origin_access_identity.iam_arn}"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.avr_derivatives.arn}"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.avr_origin_access_identity.iam_arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "allow_cloudfront_derivative_access" {
  bucket = "${aws_s3_bucket.avr_derivatives.id}"
  policy = "${data.aws_iam_policy_document.derivative_bucket_policy.json}"
}

resource "aws_cloudfront_distribution" "avr_streaming" {
  enabled          = true
  is_ipv6_enabled  = true
  retain_on_delete = true
  aliases          = ["${local.streaming_aliases}"]
  price_class      = "PriceClass_100"

  origin {
    domain_name = "${aws_s3_bucket.avr_derivatives.bucket_domain_name}"
    origin_id   = "${local.namespace}-${local.app_name}-origin-hls"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.avr_origin_access_identity.cloudfront_access_identity_path}"
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${local.namespace}-${local.app_name}-origin-hls"
    viewer_protocol_policy = "allow-all"

    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = false
      headers      = ["Origin"]
    }

    trusted_signers = "${var.trusted_signers}"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = "${var.streaming_certificate == "" ? true : false}"
    acm_certificate_arn            = "${var.streaming_certificate}"
    ssl_support_method             = "sni-only"
  }
}

resource "aws_route53_record" "avr_cloudfront" {
  zone_id = "${data.terraform_remote_state.stack.public_zone_id}"
  name    = "${local.stream_fqdn}"
  type    = "CNAME"
  ttl     = "900"
  records = ["${aws_cloudfront_distribution.avr_streaming.domain_name}"]
}
