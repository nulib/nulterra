module "solr_backup_volume" {
  source  = "cloudposse/efs/aws"
  version = "0.3.6"

  namespace          = "${var.stack_name}"
  stage              = "solr"
  name               = "backup"
  aws_region         = "${var.aws_region}"
  vpc_id             = "${module.vpc.vpc_id}"
  subnets            = "${module.vpc.private_subnets}"
  availability_zones = ["${var.azs}"]

  security_groups = [
    "${module.solr_environment.security_group_id}",
    "${aws_security_group.bastion.id}",
  ]

  zone_id = "${module.dns.private_zone_id}"

  tags = "${local.common_tags}"
}

data "template_file" "solr_dockerrun_aws_json" {
  template = "${file("./templates/solr_Dockerrun.aws.json.tpl")}"

  vars {
    aws_region = "${var.aws_region}"
    stack_name = "${local.namespace}"
  }
}

resource "local_file" "solr_dockerrun_aws_json" {
  content  = "${data.template_file.solr_dockerrun_aws_json.rendered}"
  filename = "./applications/solr/Dockerrun.aws.json"
}

data "archive_file" "solr_source" {
  depends_on  = ["local_file.solr_dockerrun_aws_json"]
  type        = "zip"
  source_dir  = "${path.module}/applications/solr"
  output_path = "${path.module}/build/solr.zip"
}

resource "aws_s3_bucket_object" "solr_source" {
  bucket = "${aws_s3_bucket.app_sources.id}"
  key    = "solr-${data.archive_file.solr_source.output_md5}.zip"
  source = "${path.module}/build/solr.zip"
  etag   = "${data.archive_file.solr_source.output_md5}"
}

resource "aws_elastic_beanstalk_application_version" "solr" {
  depends_on  = ["null_resource.wait_for_zookeeper"]
  name        = "solr-${data.archive_file.solr_source.output_md5}"
  application = "${aws_elastic_beanstalk_application.solrcloud.name}"
  description = "application version created by terraform"
  bucket      = "${aws_s3_bucket.app_sources.id}"
  key         = "${aws_s3_bucket_object.solr_source.id}"
}

resource "null_resource" "wait_for_zookeeper" {
  triggers {
    value = "${module.zookeeper_environment.name}"
  }

  provisioner "local-exec" {
    command = "while [[ $(aws elasticbeanstalk describe-environments --environment-names ${module.zookeeper_environment.name} | jq -r '.Environments[].Status') -ne 'Ready' ]]; do sleep 10; done"
  }
}

resource "aws_security_group_rule" "allow_solr_self_access" {
  security_group_id        = "${module.solr_environment.security_group_id}"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  source_security_group_id = "${module.solr_environment.security_group_id}"
}

module "solr_environment" {
  source = "../modules/beanstalk"

  app                     = "${aws_elastic_beanstalk_application.solrcloud.name}"
  version_label           = "${aws_elastic_beanstalk_application_version.solr.name}"
  namespace               = "${var.stack_name}"
  name                    = "solr"
  stage                   = "${var.environment}"
  solution_stack_name     = "${data.aws_elastic_beanstalk_solution_stack.multi_docker.name}"
  vpc_id                  = "${module.vpc.vpc_id}"
  private_subnets         = "${module.vpc.private_subnets}"
  public_subnets          = "${module.vpc.private_subnets}"
  loadbalancer_scheme     = "internal"
  managed_actions_enabled = "false"
  instance_port           = "8983"
  healthcheck_url         = "/solr/"
  keypair                 = "${var.ec2_keyname}"
  instance_type           = "t2.medium"
  extra_block_devices    = "/dev/xvdcz=:64:true:gp2"
  autoscale_min           = 3
  autoscale_max           = 4
  health_check_threshold  = "Ok"
  wait_for_ready_timeout  = "40m"
  tags                    = "${local.common_tags}"

  env_vars = {
    MOUNT_UID       = "8983"
    MOUNT_VOLUMES   = "/var/app/solr-backup=${module.solr_backup_volume.dns_name}"
    STACK_NAMESPACE = "${local.namespace}"
    STACK_NAME      = "solr"
    STACK_TIER      = "app"
    ZK_HOST         = "zk.${local.private_zone_name}"
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
