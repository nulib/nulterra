resource "aws_ses_domain_identity" "stack_domain_identity" {
  domain = "${local.public_zone_name}"
}

resource "aws_ses_domain_dkim" "stack_domain_dkim" {
  domain = "${aws_ses_domain_identity.stack_domain_identity.domain}"
}

resource "aws_route53_record" "stack_amazonses_dkim_verification_record" {
  count   = 3
  zone_id = "${module.dns.public_zone_id}"
  name    = "${element(aws_ses_domain_dkim.stack_domain_dkim.dkim_tokens, count.index)}._domainkey.${aws_ses_domain_identity.stack_domain_identity.domain}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.stack_domain_dkim.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

data "aws_iam_policy_document" "send_email" {
  statement {
    sid = "1"

    actions = [
      "ses:Send*",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "send_email" {
  name        = "${local.namespace}-send-email"
  path        = "/"
  description = "Allow stack resources to send email"
  policy      = "${data.aws_iam_policy_document.send_email.json}"
}

resource "aws_route53_record" "stack_amazonses_verification_record" {
  zone_id = "${module.dns.public_zone_id}"
  name    = "_amazonses.${aws_ses_domain_identity.stack_domain_identity.id}"
  type    = "TXT"
  ttl     = "600"
  records = ["${aws_ses_domain_identity.stack_domain_identity.verification_token}"]
}
