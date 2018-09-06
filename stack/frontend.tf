locals {
  frontend_dns_name = "dc.${local.public_zone_name}"
}

resource "aws_s3_bucket" "static_frontend_bucket" {
  bucket = "${local.frontend_dns_name}"
  acl    = "public-read"
  tags   = "${local.common_tags}"

  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

resource "aws_route53_record" "frontend_dns" {
  zone_id = "${module.dns.public_zone_id}"
  name    = "${local.frontend_dns_name}"
  type    = "A"

  alias {
    name                   = "${aws_s3_bucket.static_frontend_bucket.website_domain}"
    zone_id                = "${aws_s3_bucket.static_frontend_bucket.hosted_zone_id}"
    evaluate_target_health = true
  }
}
