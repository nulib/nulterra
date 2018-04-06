locals {
  db_schema = "fcrepo"
}

module "fcrepodb" {
  source = "../database"
  schema = "${local.db_schema}"
  host = "${module.db.this_db_instance_address}"
  port = "${module.db.this_db_instance_port}"
  master_username = "${module.db.this_db_instance_username}"
  master_password = "${module.db.this_db_instance_password}"

  connection = {
    user        = "ec2-user"
    host        = "${aws_instance.bastion.public_ip}"
    private_key = "${file(var.ec2_private_keyfile)}"
  }
}

resource "aws_s3_bucket" "fcrepo_binary_bucket" {
  bucket = "${var.stack_name}-fcrepo-binaries"
  acl = "private"
  tags = "${local.common_tags}"
}

resource "aws_iam_user" "fcrepo_binary_bucket_user" {
  name = "${var.stack_name}-fcrepo"
  path = "/system/"
}

resource "aws_iam_access_key" "fcrepo_binary_bucket_access_key" {
  user = "${aws_iam_user.fcrepo_binary_bucket_user.name}"
}

data "aws_iam_policy_document" "fcrepo_binary_bucket_access" {
  statement {
    effect = "Allow"
    actions = ["s3:ListAllMyBuckets"]
    resources = ["arn:aws:s3:::*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = ["${aws_s3_bucket.fcrepo_binary_bucket.arn}"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["${aws_s3_bucket.fcrepo_binary_bucket.arn}/*"]
  }
}

resource "aws_iam_user_policy" "fcrepo_binary_bucket_policy" {
  name = "${var.stack_name}-fcrepo-s3-bucket-access"
  user = "${aws_iam_user.fcrepo_binary_bucket_user.name}"
  policy = "${data.aws_iam_policy_document.fcrepo_binary_bucket_access.json}"
}

data "template_file" "fcrepo_task" {
  template = "${file("task_definitions/fcrepo_server.json")}"
  vars {
    db_host = "${module.db.this_db_instance_address}"
    db_port = "${module.db.this_db_instance_port}"
    db_username = "${local.db_schema}"
    db_password = "${module.fcrepodb.password}"
    aws_key = "${aws_iam_access_key.fcrepo_binary_bucket_access_key.id}"
    aws_secret = "${aws_iam_access_key.fcrepo_binary_bucket_access_key.secret}"
    aws_bucket = "${aws_s3_bucket.fcrepo_binary_bucket.id}"
  }
}

module "fcrepo_container" {
  source = "../ecs"
  name = "fcrepo"
  vpc_id = "${module.vpc.vpc_id}"
  subnets = ["${module.vpc.private_subnets}"]
  instance_type = "t2.medium"
  key_name = "${var.ec2_keyname}"
  instance_port = "8080"
  lb_port = "80"
  health_check_target = "HTTP:8080/rest"
  container_definitions = "${data.template_file.fcrepo_task.rendered}"
  client_access = [
    {
      from_port = 80
      to_port   = 80
      protocol  = "tcp"
    }
  ]
  tags = "${local.common_tags}"
}

resource "aws_security_group_rule" "allow_fedora_postgres_access" {
  type      = "ingress"
  from_port = "${module.db.this_db_instance_port}"
  to_port   = "${module.db.this_db_instance_port}"
  protocol  = "tcp"

  security_group_id = "${aws_security_group.db.id}"

  source_security_group_id = "${module.fcrepo_container.security_group}"
}

resource "aws_route53_record" "fcrepo" {
  zone_id = "${module.dns.public_zone_id}"
  name    = "fcrepo.${local.private_zone_name}"
  type    = "A"

  alias {
    name                   = "${module.fcrepo_container.lb_endpoint}"
    zone_id                = "${module.fcrepo_container.lb_zone_id}"
    evaluate_target_health = true
  }
}
