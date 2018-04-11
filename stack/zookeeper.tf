resource "aws_s3_bucket" "zookeeper_config_bucket" {
  bucket = "${var.stack_name}-zk-configs"
  acl = "private"
  tags = "${local.common_tags}"
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
  name = "${var.stack_name}-zk-config-bucket-access"
  policy = "${data.aws_iam_policy_document.zookeeper_config_bucket_access.json}"
}

resource "aws_iam_role_policy_attachment" "zookeeper_config_bucket_role_access" {
  role = "${module.zookeeper_container.role}"
  policy_arn = "${aws_iam_policy.zookeeper_config_bucket_policy.arn}"
}

data "template_file" "zookeeper_task" {
  template = "${file("task_definitions/zookeeper_server.json")}"
  vars {
    config_bucket = "${aws_s3_bucket.zookeeper_config_bucket.id}"
    region = "${var.aws_region}"
  }
}

module "zookeeper_container" {
  source = "../ecs"
  namespace = "${var.stack_name}"
  name = "zookeeper"
  vpc_id = "${module.vpc.vpc_id}"
  subnets = ["${module.vpc.private_subnets}"]
  instance_type = "t2.medium"
  key_name = "${var.ec2_keyname}"
  instance_port = "8181"
  lb_port = "80"
  health_check_target = "HTTP:8181/exhibitor/v1/ui/index.html"
  container_definitions = "${data.template_file.zookeeper_task.rendered}"
  min_size = 2
  max_size = 2
  desired_capacity = 2
  client_access = [
    {
      from_port = 80
      to_port   = 80
      protocol  = "tcp"
    }
  ]
  tags = "${local.common_tags}"
}

locals {
  client_ports = [2181, 2888, 3888, 8181]
}

resource "aws_security_group_rule" "allow_zk_solr_access" {
  count     = "${length(local.client_ports)}"
  type      = "ingress"
  from_port = "${local.client_ports[count.index]}"
  to_port   = "${local.client_ports[count.index]}"
  protocol  = "tcp"

  security_group_id = "${module.zookeeper_container.security_group}"

  source_security_group_id = "${module.solr_container.security_group}"
}

resource "aws_security_group_rule" "allow_zk_client_access" {
  count     = "${length(local.client_ports)}"
  type      = "ingress"
  from_port = "${local.client_ports[count.index]}"
  to_port   = "${local.client_ports[count.index]}"
  protocol  = "tcp"

  security_group_id = "${module.zookeeper_container.security_group}"

  source_security_group_id = "${module.zookeeper_container.client_security_group}"
}

resource "aws_security_group_rule" "allow_zk_self_access" {
  count     = "${length(local.client_ports)}"
  type      = "ingress"
  from_port = "${local.client_ports[count.index]}"
  to_port   = "${local.client_ports[count.index]}"
  protocol  = "tcp"

  security_group_id = "${module.zookeeper_container.security_group}"

  source_security_group_id = "${module.zookeeper_container.security_group}"
}

resource "aws_route53_record" "zookeeper" {
  zone_id = "${module.dns.private_zone_id}"
  name    = "zookeeper.${local.private_zone_name}"
  type    = "A"

  alias {
    name                   = "${module.zookeeper_container.lb_endpoint}"
    zone_id                = "${module.zookeeper_container.lb_zone_id}"
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
  name = "${var.stack_name}-upsert-zk-records"
  description = "Upsert Route53 records for Zookeeper on scaling"
  event_pattern = <<PATTERN
{
  "source": ["aws.autoscaling"],
  "detail-type": [
    "EC2 Instance Launch Successful",
    "EC2 Instance Terminate Successful"
  ],
  "detail": {
    "AutoScalingGroupName": ["${module.zookeeper_container.asg}"]
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

  function_name = "${var.stack_name}-upsert-zk-route53-records"
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
    zookeeper_asg = "${module.zookeeper_container.asg}"
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
    zookeeper_asg = "${module.zookeeper_container.asg}"
  }
}

resource "null_resource" "first_run_upsert_zk_records" {
  provisioner "local-exec" {
    command = "aws lambda invoke --function-name ${var.stack_name}-upsert-zk-route53-records --payload '${data.template_file.first_run_upsert_zk_records_payload.rendered}' /dev/null"
  }

  provisioner "local-exec" {
    when = "destroy"
    command = "aws lambda invoke --function-name ${var.stack_name}-upsert-zk-route53-records --payload '${data.template_file.delete_zk_records_change_batch.rendered}' /dev/null"
  }
}
