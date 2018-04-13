module "backup_volume" {
  source  = "cloudposse/efs/aws"
  version = "0.3.3"

  namespace          = "${var.stack_name}"
  stage              = "solr"
  name               = "backup"
  aws_region         = "${var.aws_region}"
  vpc_id             = "${module.vpc.vpc_id}"
  subnets            = "${module.vpc.private_subnets}"
  availability_zones = ["${var.azs}"]
  security_groups    = ["${module.solr_environment.security_group_id}"]

  zone_id = "${module.dns.private_zone_id}"

  tags = "${local.common_tags}"
}

data "archive_file" "solr_source" {
  type        = "zip"
  source_dir  = "${path.module}/applications/solr"
  output_path = "${path.module}/build/solr.zip"
}

resource "aws_s3_bucket_object" "solr_source" {
  bucket = "${aws_s3_bucket.app_sources.id}"
  key    = "solr.zip"
  source = "${path.module}/build/solr.zip"
  etag   = "${data.archive_file.solr_source.output_md5}"
}

resource "aws_elastic_beanstalk_application" "solr" {
  name = "${var.stack_name}-solr"
}

resource "aws_elastic_beanstalk_application_version" "solr" {
  name        = "solr-${data.archive_file.solr_source.output_md5}"
  application = "${aws_elastic_beanstalk_application.solr.name}"
  description = "application version created by terraform"
  bucket      = "${aws_s3_bucket.app_sources.id}"
  key         = "${aws_s3_bucket_object.solr_source.id}"
}

module "solr_environment" {
  source = "git://github.com/nulib/terraform-aws-elastic-beanstalk-environment"

  app                  = "${aws_elastic_beanstalk_application.solr.name}"
  version_label        = "${aws_elastic_beanstalk_application_version.solr.name}"
  namespace            = "${var.stack_name}"
  name                 = "solr"
  stage                = "${var.environment}"
  solution_stack_name  = "${data.aws_elastic_beanstalk_solution_stack.multi_docker.name}"
  vpc_id               = "${module.vpc.vpc_id}"
  private_subnets      = "${module.vpc.private_subnets}"
  public_subnets       = "${module.vpc.private_subnets}"
  loadbalancer_scheme  = "internal"
  healthcheck_url      = "/solr"
  keypair              = "${var.ec2_keyname}"
  instance_type        = "t2.medium"
  security_groups      = ["${aws_security_group.bastion.id}"]
  ssh_listener_enabled = "true"
  autoscale_min        = 3
  autoscale_max        = 4
  env_vars = {
    MOUNT_VOLUMES = "/var/app/solr-backup=${module.backup_volume.dns_name}",
    ZK_HOST       = "zk.${local.private_zone_name}"
  }
}

resource "aws_route53_record" "solr" {
  zone_id = "${module.dns.private_zone_id}"
  name    = "solr.${local.private_zone_name}"
  type    = "A"

  alias {
    name                   = "${module.solr_environment.elb_dns_name}"
    zone_id                = "${module.solr_environment.elb_zone_id}"
    evaluate_target_health = true
  }
}
