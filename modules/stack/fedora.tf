locals {
  fcrepo_db_schema = "fcrepo"
}

data "archive_file" "fcrepo_source" {
  type        = "zip"
  source_dir  = "${path.module}/applications/fcrepo"
  output_path = "${path.module}/build/fcrepo.zip"
}

resource "aws_s3_bucket_object" "fcrepo_source" {
  bucket = "${aws_s3_bucket.app_sources.id}"
  key    = "fcrepo.zip"
  source = "${path.module}/build/fcrepo.zip"
  etag   = "${data.archive_file.fcrepo_source.output_md5}"
}

module "fcrepodb" {
  source          = "../database"
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

resource "aws_s3_bucket" "fcrepo_binary_bucket" {
  bucket = "${local.namespace}-fcrepo-binaries"
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

resource "aws_elastic_beanstalk_application" "fcrepo" {
  name = "${local.namespace}-fcrepo"
}

resource "aws_elastic_beanstalk_application_version" "fcrepo" {
  name        = "fcrepo-${data.archive_file.fcrepo_source.output_md5}"
  application = "${aws_elastic_beanstalk_application.fcrepo.name}"
  description = "application version created by terraform"
  bucket      = "${aws_s3_bucket.app_sources.id}"
  key         = "${aws_s3_bucket_object.fcrepo_source.id}"
}

module "fcrepo_environment" {
  source = "../beanstalk"

  app                    = "${aws_elastic_beanstalk_application.fcrepo.name}"
  version_label          = "${aws_elastic_beanstalk_application_version.fcrepo.name}"
  namespace              = "${var.stack_name}"
  name                   = "fcrepo"
  stage                  = "${var.environment}"
  solution_stack_name    = "${data.aws_elastic_beanstalk_solution_stack.multi_docker.name}"
  vpc_id                 = "${module.vpc.vpc_id}"
  private_subnets        = "${module.vpc.private_subnets}"
  public_subnets         = "${module.vpc.private_subnets}"
  loadbalancer_scheme    = "internal"
  instance_port          = "8080"
  healthcheck_url        = "/rest"
  keypair                = "${var.ec2_keyname}"
  instance_type          = "m4.xlarge"
  autoscale_min          = 1
  autoscale_max          = 2
  health_check_threshold = "Severe"
  tags                   = "${local.common_tags}"

  env_vars = {
    JAVA_OPTIONS = "-Dfcrepo.postgresql.host=${module.db.this_db_instance_address} -Dfcrepo.postgresql.port=${module.db.this_db_instance_port} -Dfcrepo.postgresql.username=${local.fcrepo_db_schema} -Dfcrepo.postgresql.password=${module.fcrepodb.password} -Daws.accessKeyId=${aws_iam_access_key.fcrepo_binary_bucket_access_key.id} -Daws.secretKey=${aws_iam_access_key.fcrepo_binary_bucket_access_key.secret} -Daws.bucket=${aws_s3_bucket.fcrepo_binary_bucket.id}"
  }
}

resource "aws_security_group_rule" "allow_fedora_postgres_access" {
  security_group_id        = "${aws_security_group.db.id}"
  type                     = "ingress"
  from_port                = "${module.db.this_db_instance_port}"
  to_port                  = "${module.db.this_db_instance_port}"
  protocol                 = "tcp"
  source_security_group_id = "${module.fcrepo_environment.security_group_id}"
}

resource "aws_route53_record" "fcrepo" {
  zone_id = "${module.dns.private_zone_id}"
  name    = "fcrepo.${local.private_zone_name}"
  type    = "A"

  alias {
    name                   = "${module.fcrepo_environment.elb_dns_name}"
    zone_id                = "${module.fcrepo_environment.elb_zone_id}"
    evaluate_target_health = true
  }
}
