resource "aws_s3_bucket" "zookeeper_config_bucket" {
  bucket = "${local.namespace}-zk-configs"
  acl = "private"
  tags = "${local.common_tags}"
  force_destroy = true
}

data "aws_iam_policy_document" "zookeeper_config_bucket_access" {
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
    resources = ["${aws_s3_bucket.zookeeper_config_bucket.arn}"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["${aws_s3_bucket.zookeeper_config_bucket.arn}/*"]
  }
}

resource "aws_iam_policy" "zookeeper_config_bucket_policy" {
  name = "${local.namespace}-zk-config-bucket-access"
  policy = "${data.aws_iam_policy_document.zookeeper_config_bucket_access.json}"
}

resource "aws_iam_role_policy_attachment" "zookeeper_config_bucket_role_access" {
  role = "${module.zookeeper_environment.ec2_instance_profile_role_name}"
  policy_arn = "${aws_iam_policy.zookeeper_config_bucket_policy.arn}"
}

data "archive_file" "zookeeper_source" {
  type        = "zip"
  source_dir  = "${path.module}/applications/zookeeper"
  output_path = "${path.module}/build/zookeeper.zip"
}

resource "aws_s3_bucket_object" "zookeeper_source" {
  bucket = "${aws_s3_bucket.app_sources.id}"
  key    = "zookeeper.zip"
  source = "${path.module}/build/zookeeper.zip"
  etag   = "${data.archive_file.zookeeper_source.output_md5}"
}

resource "aws_elastic_beanstalk_application_version" "zookeeper" {
  name        = "zookeeper-${data.archive_file.zookeeper_source.output_md5}"
  application = "${aws_elastic_beanstalk_application.solrcloud.name}"
  description = "application version created by terraform"
  bucket      = "${aws_s3_bucket.app_sources.id}"
  key         = "${aws_s3_bucket_object.zookeeper_source.id}"
}

module "zookeeper_environment" {
  source = "../modules/beanstalk"

  app                    = "${aws_elastic_beanstalk_application.solrcloud.name}"
  version_label          = "${aws_elastic_beanstalk_application_version.zookeeper.name}"
  namespace              = "${var.stack_name}"
  name                   = "zookeeper"
  stage                  = "${var.environment}"
  solution_stack_name    = "${data.aws_elastic_beanstalk_solution_stack.multi_docker.name}"
  vpc_id                 = "${module.vpc.vpc_id}"
  private_subnets        = "${module.vpc.private_subnets}"
  public_subnets         = "${module.vpc.private_subnets}"
  loadbalancer_scheme    = "internal"
  instance_port          = "8181"
  healthcheck_url        = "/exhibitor/v1/ui/index.html"
  keypair                = "${var.ec2_keyname}"
  instance_type          = "t2.medium"
  autoscale_min          = 2
  autoscale_max          = 3
  health_check_threshold = "Severe"
  tags                   = "${local.common_tags}"

  env_vars = {
    S3_BUCKET        = "${aws_s3_bucket.zookeeper_config_bucket.id}",
    S3_PREFIX        = "zookeeper",
    AWS_REGION       = "${var.aws_region}",
    DYNAMIC_HOSTNAME = "true"
  }
}

resource "aws_security_group_rule" "allow_zk_solr_access" {
  security_group_id        = "${module.zookeeper_environment.security_group_id}"
  type                     = "ingress"
  from_port                = "2181"
  to_port                  = "2181"
  protocol                 = "tcp"
  source_security_group_id = "${module.solr_environment.security_group_id}"
}

resource "aws_security_group_rule" "allow_zk_self_access" {
  security_group_id        = "${module.zookeeper_environment.security_group_id}"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  source_security_group_id = "${module.zookeeper_environment.security_group_id}"
}

resource "aws_route53_record" "zookeeper" {
  zone_id = "${module.dns.private_zone_id}"
  name    = "zookeeper.${local.private_zone_name}"
  type    = "A"

  alias {
    name                   = "${module.zookeeper_environment.elb_dns_name}"
    zone_id                = "${module.zookeeper_environment.elb_zone_id}"
    evaluate_target_health = true
  }
}

data "aws_iam_policy_document" "upsert_route53_access" {
  statement {
    effect    = "Allow"
    actions   = [
      "route53:ListResourceRecordSets",
      "route53:ChangeResourceRecordSets"
    ]
    resources = ["arn:aws:route53:::hostedzone/${module.dns.private_zone_id}"]
  }

  statement {
    effect    = "Allow"
    actions   = [
      "autoscaling:DescribeAutoScalingGroups",
      "ec2:DescribeInstances"
    ]
    resources = ["*"]
  }
}

resource "aws_cloudwatch_event_rule" "upsert_zk_records_event" {
  name = "${local.namespace}-upsert-zk-records"
  description = "Upsert Route53 records for Zookeeper on scaling"
  event_pattern = <<PATTERN
{
  "source": ["aws.autoscaling"],
  "detail-type": [
    "EC2 Instance Launch Successful",
    "EC2 Instance Terminate Successful"
  ],
  "detail": {
    "AutoScalingGroupName": ["${module.zookeeper_environment.autoscaling_groups[0]}"]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule = "${aws_cloudwatch_event_rule.upsert_zk_records_event.name}"
  arn = "${module.upsert_zk_records.function_arn}"
}

resource "aws_lambda_permission" "upsert_invoke_permission" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = "${module.upsert_zk_records.function_name}"
  principal = "events.amazonaws.com"
}

module "upsert_zk_records" {
  source = "git://github.com/claranet/terraform-aws-lambda"

  function_name = "${local.namespace}-upsert-zk-route53-records"
  description   = "Upsert Route53 records for Zookeeper on scaling"
  handler       = "index.handler"
  runtime       = "nodejs4.3"
  timeout       = 300

  attach_policy = true
  policy        = "${data.aws_iam_policy_document.upsert_route53_access.json}"

  source_path = "${path.module}/lambdas/upsert_zk_records"
  environment {
    variables {
      RecordSetName = "zk.${local.private_zone_name}"
      HostedZoneId = "${module.dns.private_zone_id}"
    }
  }
}

data "template_file" "first_run_upsert_zk_records_payload" {
  template = <<EOF
{
  "RequestType": "Create",
  "ResourceProperties": {
    "ZookeeperASGName": "$${zookeeper_asg}"
  }
}
EOF
  vars {
    zookeeper_asg = "${module.zookeeper_environment.autoscaling_groups[0]}"
  }
}

data "template_file" "delete_zk_records_change_batch" {
  template = <<EOF
{
  "RequestType": "Delete",
  "ResourceProperties": {
    "ZookeeperASGName": "$${zookeeper_asg}"
  }
}
EOF
  vars {
    zookeeper_asg = "${module.zookeeper_environment.autoscaling_groups[0]}"
  }
}

resource "null_resource" "first_run_upsert_zk_records" {
  provisioner "local-exec" {
    command = "aws lambda invoke --function-name ${local.namespace}-upsert-zk-route53-records --payload '${data.template_file.first_run_upsert_zk_records_payload.rendered}' /dev/null"
  }

  provisioner "local-exec" {
    when = "destroy"
    command = "aws lambda invoke --function-name ${local.namespace}-upsert-zk-route53-records --payload '${data.template_file.delete_zk_records_change_batch.rendered}' /dev/null"
  }
}
