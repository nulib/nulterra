locals {
  fcrepo_db_schema = "fcrepo"
}

module "fcrepodb" {
  source          = "../modules/database"
  schema          = "${local.fcrepo_db_schema}"
  host            = "${module.db.this_db_instance_address}"
  port            = "${module.db.this_db_instance_port}"
  master_username = "${module.db.this_db_instance_username}"
  master_password = "${module.db.this_db_instance_password}"

  connection = {
    user        = "ec2-user"
    host        = "${aws_instance.bastion.public_ip}"
    private_key = "${file(var.ec2_private_keyfile)}"
  }
}

resource "aws_security_group_rule" "allow_fcrepo_postgres_access" {
  security_group_id        = "${aws_security_group.db.id}"
  type                     = "ingress"
  from_port                = "${module.db.this_db_instance_port}"
  to_port                  = "${module.db.this_db_instance_port}"
  protocol                 = "tcp"
  source_security_group_id = "${module.fcrepo_service.instance_security_group}"
}

resource "aws_s3_bucket" "fcrepo_binary_bucket" {
  bucket = "${local.namespace}-fedora-binaries"
  acl    = "private"
  tags   = "${local.common_tags}"
}

resource "aws_iam_user" "fcrepo_binary_bucket_user" {
  name = "${local.namespace}-fcrepo"
  path = "/system/"
}

resource "aws_iam_access_key" "fcrepo_binary_bucket_access_key" {
  user = "${aws_iam_user.fcrepo_binary_bucket_user.name}"
}

data "aws_iam_policy_document" "fcrepo_binary_bucket_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["arn:aws:s3:::*"]
  }

  statement {
    effect    = "Allow"
    actions   = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = ["${aws_s3_bucket.fcrepo_binary_bucket.arn}"]
  }

  statement {
    effect    = "Allow"
    actions   = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["${aws_s3_bucket.fcrepo_binary_bucket.arn}/*"]
  }
}

resource "aws_iam_user_policy" "fcrepo_binary_bucket_policy" {
  name   = "${local.namespace}-fcrepo-s3-bucket-access"
  user   = "${aws_iam_user.fcrepo_binary_bucket_user.name}"
  policy = "${data.aws_iam_policy_document.fcrepo_binary_bucket_access.json}"
}

resource "aws_security_group" "fcrepo_client_security_group" {
  name        = "${local.namespace}-fedora-client"
  description = "Fedora Security Group"
  vpc_id      = "${module.vpc.vpc_id}"
  tags        = "${local.common_tags}"
}

resource "aws_security_group_rule" "allow_fcrepo_clients_lb_access" {
  security_group_id        = "${module.fcrepo_service.lb_security_group}"
  type                     = "ingress"
  from_port                = "80"
  to_port                  = "80"
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.fcrepo_client_security_group.id}"
}

data "template_file" "fcrepo_task_definition" {
  template = "${file("${path.module}/applications/fcrepo/service.json.tpl")}"

  vars = {
    db_host                  = "${module.db.this_db_instance_address}"
    db_port                  = "${module.db.this_db_instance_port}"
    db_user                  = "${local.fcrepo_db_schema}"
    db_password              = "${module.fcrepodb.password}"
    bucket_name              = "${aws_s3_bucket.fcrepo_binary_bucket.id}"
    bucket_access_key_id     = "${aws_iam_access_key.fcrepo_binary_bucket_access_key.id}"
    bucket_access_key_secret = "${aws_iam_access_key.fcrepo_binary_bucket_access_key.secret}"
    namespace                = "${local.namespace}"
    aws_region               = "${var.aws_region}"
  }
}

module "fcrepo_service" {
  source                = "../modules/fargate"

  container_definitions = "${data.template_file.fcrepo_task_definition.rendered}"
  container_name        = "fcrepo-app"
  cpu                   = "1024"
  family                = "fedora"
  instance_port         = "8080"
  memory                = "8192"
  namespace             = "${local.namespace}"
  private_subnets       = ["${module.vpc.private_subnets}"]
  public_subnets        = ["${module.vpc.public_subnets}"]
  security_groups       = ["${module.vpc.default_security_group_id}"]
  tags                  = "${local.common_tags}"
  vpc_id                = "${module.vpc.vpc_id}"
}

resource "aws_route53_record" "fcrepo" {
  zone_id = "${module.dns.private_zone_id}"
  name    = "fcrepo.${local.private_zone_name}"
  type    = "A"

  alias {
    name                   = "${module.fcrepo_service.lb_dns_name}"
    zone_id                = "${module.fcrepo_service.lb_zone_id}"
    evaluate_target_health = true
  }
}
