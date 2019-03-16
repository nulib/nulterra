resource "aws_security_group" "elasticsearch" {
  name   = "${local.namespace}-elasticsearch"
}

resource "aws_security_group_rule" "elasticsearch_egress" {
  security_group_id  = "${aws_security_group.elasticsearch.id}"
  type               = "egress"
  from_port          = "0"
  to_port            = "0"
  protocol           = "-1"
  cidr_blocks        = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "elasticsearch_ingress" {
  security_group_id  = "${aws_security_group.elasticsearch.id}"
  type               = "ingress"
  from_port          = "443"
  to_port            = "443"
  protocol           = "tcp"
  cidr_blocks        = ["0.0.0.0/0"]
}

resource "aws_elasticsearch_domain" "elasticsearch" {
  domain_name           = "${local.namespace}-common-index"
  elasticsearch_version = "6.2"
  tags                  = "${local.common_tags}"
  cluster_config {
    instance_type = "t2.medium.elasticsearch"
  }
  ebs_options {
    ebs_enabled = "true"
    volume_size = 10
  }
  access_policies = "${data.aws_iam_policy_document.elasticsearch_http_access.json}"
}

data "aws_iam_policy_document" "elasticsearch_http_access" {
  statement {
    effect    = "Allow"
    actions   = ["es:ESHttp*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_iam_service_linked_role" "elasticsearch" {
  aws_service_name = "es.amazonaws.com"
}

resource "aws_s3_bucket" "elasticsearch_snapshot_bucket" {
  bucket = "${local.namespace}-es-snapshots"
  acl    = "private"
  tags   = "${local.common_tags}"
}

resource "aws_iam_role" "elasticsearch_snapshot_bucket_access" {
  name                  = "${local.namespace}-es-snapshot-role"
  assume_role_policy    = "${data.aws_iam_policy_document.elasticsearch_snapshot_assume_role.json}"
  tags                  = "${local.common_tags}"
}

resource "aws_iam_role_policy" "elasticsearch_snapshot_bucket_access" {
  name   = "${local.namespace}-es-snapshot-policy"
  role   = "${aws_iam_role.elasticsearch_snapshot_bucket_access.name}"
  policy = "${data.aws_iam_policy_document.elasticsearch_snapshot_bucket_access.json}"
}

data "aws_iam_policy_document" "elasticsearch_snapshot_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["es.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "elasticsearch_snapshot_bucket_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.elasticsearch_snapshot_bucket.arn}"]
  }

  statement {
    effect    = "Allow"
    actions   = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["${aws_s3_bucket.elasticsearch_snapshot_bucket.arn}/*"]
  }
}
