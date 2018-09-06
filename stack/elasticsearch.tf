resource "aws_security_group" "elasticsearch" {
  name   = "${local.namespace}-elasticsearch"
  vpc_id = "${module.vpc.vpc_id}"
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
  cidr_blocks        = ["${var.vpc_cidr_block}"]
}

data "aws_iam_policy_document" "elasticsearch_access" {
  statement {
    effect  = "Allow"
    actions = ["es:*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_elasticsearch_domain" "elasticsearch" {
  domain_name           = "${local.namespace}-common-index"
  elasticsearch_version = "6.2"
  access_policies       = "${data.aws_iam_policy_document.elasticsearch_access.json}"
  tags                  = "${local.common_tags}"
  vpc_options {
    security_group_ids = ["${aws_security_group.elasticsearch.id}"]
    subnet_ids         = ["${element(module.vpc.private_subnets, 1)}"]
  }
  cluster_config {
    instance_type = "t2.medium.elasticsearch"
  }
  ebs_options {
    ebs_enabled = "true"
    volume_size = 10
  }
}

resource "aws_iam_service_linked_role" "elasticsearch" {
  aws_service_name = "es.amazonaws.com"
}
