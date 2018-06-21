locals {
  stream_fqdn = "httpstream.${data.terraform_remote_state.stack.stack_name}.${data.terraform_remote_state.stack.hosted_zone_name}"
}

resource "aws_cloudfront_origin_access_identity" "avr_origin_access_identity" {
  comment = "${local.namespace}-${local.app_name}"
}

resource "aws_cloudfront_distribution" "avr_streaming" {
  enabled          = true
  is_ipv6_enabled  = true
  retain_on_delete = true
  aliases          = ["${local.stream_fqdn}"]
  price_class      = "PriceClass_100"

  origin {
    domain_name = "${data.aws_s3_bucket.existing_avr_derivatives.bucket_domain_name}"
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
    cloudfront_default_certificate = true
  }
}

resource "aws_route53_record" "avr_cloudfront" {
  zone_id = "${data.terraform_remote_state.stack.public_zone_id}"
  name    = "${local.stream_fqdn}"
  type    = "CNAME"
  ttl     = "900"
  records = ["${aws_cloudfront_distribution.avr_streaming.domain_name}"]
}
