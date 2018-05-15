locals {
  environment_label = "${var.namespace}-${var.stage}-${var.name}"
}

data "aws_region" "default" {}

#
# Service
#
data "aws_iam_policy_document" "service" {
  statement {
    sid = ""

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["elasticbeanstalk.amazonaws.com"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "service" {
  name               = "${local.environment_label}-service"
  assume_role_policy = "${data.aws_iam_policy_document.service.json}"
}

resource "aws_iam_role_policy_attachment" "enhanced-health" {
  role       = "${aws_iam_role.service.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "service" {
  role       = "${aws_iam_role.service.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

#
# EC2
#
data "aws_iam_policy_document" "ec2" {
  statement {
    sid = ""

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    effect = "Allow"
  }

  statement {
    sid = ""

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${local.environment_label}-ec2"
  assume_role_policy = "${data.aws_iam_policy_document.ec2.json}"
}

resource "aws_iam_role_policy" "default" {
  name   = "${local.environment_label}-default"
  role   = "${aws_iam_role.ec2.id}"
  policy = "${data.aws_iam_policy_document.default.json}"
}

resource "aws_iam_role_policy_attachment" "web-tier" {
  role       = "${aws_iam_role.ec2.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "worker-tier" {
  role       = "${aws_iam_role.ec2.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "ssm-ec2" {
  role       = "${aws_iam_role.ec2.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "ssm-automation" {
  role       = "${aws_iam_role.ec2.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"

  lifecycle {
    create_before_destroy = true
  }
}

# http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/create_deploy_docker.container.console.html
# http://docs.aws.amazon.com/AmazonECR/latest/userguide/ecr_managed_policies.html#AmazonEC2ContainerRegistryReadOnly
resource "aws_iam_role_policy_attachment" "ecr-readonly" {
  role       = "${aws_iam_role.ec2.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_ssm_activation" "ec2" {
  name               = "${local.environment_label}"
  iam_role           = "${aws_iam_role.ec2.id}"
  registration_limit = "${var.autoscale_max}"
}

data "aws_iam_policy_document" "default" {
  statement {
    sid = ""

    actions = [
      "elasticloadbalancing:DescribeInstanceHealth",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTargetHealth",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:GetConsoleOutput",
      "ec2:AssociateAddress",
      "ec2:DescribeAddresses",
      "ec2:DescribeSecurityGroups",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeNotificationConfigurations",
    ]

    resources = ["*"]

    effect = "Allow"
  }

  statement {
    sid = "AllowOperations"

    actions = [
      "autoscaling:AttachInstances",
      "autoscaling:CreateAutoScalingGroup",
      "autoscaling:CreateLaunchConfiguration",
      "autoscaling:DeleteLaunchConfiguration",
      "autoscaling:DeleteAutoScalingGroup",
      "autoscaling:DeleteScheduledAction",
      "autoscaling:DescribeAccountLimits",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeLoadBalancers",
      "autoscaling:DescribeNotificationConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeScheduledActions",
      "autoscaling:DetachInstances",
      "autoscaling:PutScheduledUpdateGroupAction",
      "autoscaling:ResumeProcesses",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:SuspendProcesses",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
      "cloudwatch:PutMetricAlarm",
      "ec2:AssociateAddress",
      "ec2:AllocateAddress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeKeyPairs",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:DisassociateAddress",
      "ec2:ReleaseAddress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:TerminateInstances",
      "ecs:*",
      "elasticbeanstalk:*",
      "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
      "elasticloadbalancing:ConfigureHealthCheck",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DescribeInstanceHealth",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "iam:ListRoles",
      "iam:PassRole",
      "logs:CreateLogGroup",
      "logs:PutRetentionPolicy",
      "rds:DescribeDBEngineVersions",
      "rds:DescribeDBInstances",
      "rds:DescribeOrderableDBInstanceOptions",
      "s3:CopyObject",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectMetadata",
      "s3:ListBucket",
      "s3:listBuckets",
      "s3:ListObjects",
      "sns:CreateTopic",
      "sns:GetTopicAttributes",
      "sns:ListSubscriptionsByTopic",
      "sns:Subscribe",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "codebuild:CreateProject",
      "codebuild:DeleteProject",
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["*"]

    effect = "Allow"
  }

  statement {
    sid = "AllowS3OperationsOnElasticBeanstalkBuckets"

    actions = [
      "s3:*",
    ]

    resources = [
      "arn:aws:s3:::*",
    ]

    effect = "Allow"
  }

  statement {
    sid = "AllowDeleteCloudwatchLogGroups"

    actions = [
      "logs:DeleteLogGroup",
    ]

    resources = [
      "arn:aws:logs:*:*:log-group:/aws/elasticbeanstalk*",
    ]

    effect = "Allow"
  }

  statement {
    sid = "AllowCloudformationOperationsOnElasticBeanstalkStacks"

    actions = [
      "cloudformation:*",
    ]

    resources = [
      "arn:aws:cloudformation:*:*:stack/awseb-*",
      "arn:aws:cloudformation:*:*:stack/eb-*",
    ]

    effect = "Allow"
  }
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.environment_label}-ec2"
  role = "${aws_iam_role.ec2.name}"
}

resource "aws_security_group" "default" {
  name        = "${local.environment_label}"
  description = "Allow inbound traffic from provided Security Groups"
  vpc_id      = "${var.vpc_id}"
  tags        = "${var.tags}"
}

resource "aws_security_group_rule" "egress_rule" {
  security_group_id = "${aws_security_group.default.id}"
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

#
# Full list of options:
# http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/command-options-general.html#command-options-general-elasticbeanstalkmanagedactionsplatformupdate
#
resource "aws_elastic_beanstalk_environment" "default" {
  name          = "${local.environment_label}"
  application   = "${var.app}"
  version_label = "${var.version_label}"

  tier                = "${var.tier}"
  solution_stack_name = "${var.solution_stack_name}"

  wait_for_ready_timeout = "${var.wait_for_ready_timeout}"

  tags = "${var.tags}"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = "${var.vpc_id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "${var.associate_public_ip_address}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${join(",", var.private_subnets)}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${join(",", var.public_subnets)}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = "${var.loadbalancer_scheme}"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateType"
    value     = "${var.rolling_update_type}"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "MinInstancesInService"
    value     = "${var.updating_min_in_service}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "DeploymentPolicy"
    value     = "${var.rolling_update_type == "Immutable" ? "Immutable" : "Rolling"}"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "MaxBatchSize"
    value     = "${var.updating_max_batch}"
  }

  ###=========================== Autoscale trigger ========================== ###

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "MeasureName"
    value     = "CPUUtilization"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Statistic"
    value     = "Average"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Unit"
    value     = "Percent"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerThreshold"
    value     = "${var.autoscale_lower_bound}"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperThreshold"
    value     = "${var.autoscale_upper_bound}"
  }

  ###=========================== Autoscale trigger ========================== ###

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = "${aws_security_group.default.id}"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SSHSourceRestriction"
    value     = "tcp,22,22,${var.ssh_source_restriction}"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "${var.instance_type}"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "${aws_iam_instance_profile.ec2.name}"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = "${var.keypair}"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "RootVolumeSize"
    value     = "${var.root_volume_size}"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "RootVolumeType"
    value     = "${var.root_volume_type}"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "Availability Zones"
    value     = "${var.availability_zones}"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "${var.autoscale_min}"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "${var.autoscale_max}"
  }
  setting {
    namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:customoption" : "aws:elb:loadbalancer"}"
    name      = "${var.tier == "Worker" ? "awselbloadbalancerCrossZone" : "CrossZone"}"
    value     = "true"
  }
  setting {
    namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:customoption" : "aws:elb:listener"}"
    name      = "${var.tier == "Worker" ? "awselblistenerListenerProtocol" : "ListenerProtocol"}"
    value     = "HTTP"
  }
  setting {
    namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:customoption" : "aws:elb:listener"}"
    name      = "${var.tier == "Worker" ? "awselblistenerInstancePort" : "InstancePort"}"
    value     = "${var.instance_port}"
  }
  setting {
    namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:customoption" : "aws:elb:listener"}"
    name      = "${var.tier == "Worker" ? "awselblistenerListenerEnabled" : "ListenerEnabled"}"
    value     = "${var.http_listener_enabled  == "true" || var.loadbalancer_certificate_arn == "" ? "true" : "false"}"
  }
  setting {
    namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:customoption" : "aws:elb:listener:443"}"
    name      = "${var.tier == "Worker" ? "awselblistener443ListenerProtocol" : "ListenerProtocol"}"
    value     = "HTTPS"
  }
  setting {
    namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:customoption" : "aws:elb:listener:443"}"
    name      = "${var.tier == "Worker" ? "awselblistener443InstancePort" : "InstancePort"}"
    value     = "${var.instance_port}"
  }
  setting {
    namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:customoption" : "aws:elb:listener:443"}"
    name      = "${var.tier == "Worker" ? "awselblistener443SSLCertificateId" : "SSLCertificateId"}"
    value     = "${var.loadbalancer_certificate_arn}"
  }
  setting {
    namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:customoption" : "aws:elb:listener:443"}"
    name      = "${var.tier == "Worker" ? "awselblistener443ListenerEnabled" : "ListenerEnabled"}"
    value     = "${var.loadbalancer_certificate_arn == "" ? "false" : "true"}"
  }
  setting {
    namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:customoption" : "aws:elb:policies"}"
    name      = "${var.tier == "Worker" ? "awselbpoliciesConnectionDrainingEnabled" : "ConnectionDrainingEnabled"}"
    value     = "true"
  }
  setting {
    namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:customoption" : "aws:elbv2:loadbalancer"}"
    name      = "${var.tier == "Worker" ? "awselbv2loadbalancerAccessLogsS3Bucket" : "AccessLogsS3Bucket"}"
    value     = "${aws_s3_bucket.elb_logs.id}"
  }
  setting {
    namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:customoption" : "aws:elbv2:loadbalancer"}"
    name      = "${var.tier == "Worker" ? "awselbv2loadbalancerAccessLogsS3Enabled" : "AccessLogsS3Enabled"}"
    value     = "true"
  }
  setting {
    namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:customoption" : "aws:elbv2:listener:default"}"
    name      = "${var.tier == "Worker" ? "awselbv2listenerListenerEnabled" : "ListenerEnabled"}"
    value     = "${var.http_listener_enabled == "true" || var.loadbalancer_certificate_arn == "" ? "true" : "false"}"
  }
  setting {
    namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:customoption" : "aws:elbv2:listener:443"}"
    name      = "${var.tier == "Worker" ? "awselbv2listenerListenerEnabled" : "ListenerEnabled"}"
    value     = "${var.loadbalancer_certificate_arn == "" ? "false" : "true"}"
  }
  setting {
    namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:customoption" : "aws:elbv2:listener:443"}"
    name      = "${var.tier == "Worker" ? "awselbv2listenerProtocol" : "Protocol"}"
    value     = "HTTPS"
  }
  setting {
    namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:customoption" : "aws:elbv2:listener:443"}"
    name      = "${var.tier == "Worker" ? "awselbv2listenerSSLCertificateArns" : "SSLCertificateArns"}"
    value     = "${var.loadbalancer_certificate_arn}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "ConfigDocument"
    value     = "${var.config_document}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application"
    name      = "Application Healthcheck URL"
    value     = "HTTP:${var.instance_port}${var.healthcheck_url}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "${var.loadbalancer_type}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = "${aws_iam_role.service.name}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "HealthCheckSuccessThreshold"
    value     = "${var.health_check_threshold}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSizeType"
    value     = "Fixed"
  }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSize"
    value     = "1"
  }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "DeploymentPolicy"
    value     = "Rolling"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "BASE_HOST"
    value     = "${var.name}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "CONFIG_SOURCE"
    value     = "${var.config_source}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "ManagedActionsEnabled"
    value     = "true"
  }
  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "PreferredStartTime"
    value     = "${var.preferred_start_time}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name      = "UpdateLevel"
    value     = "${var.update_level}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name      = "InstanceRefreshEnabled"
    value     = "${var.instance_refresh_enabled}"
  }
  ###===================== Application ENV vars ======================###
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 0))), 0)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 0))), 0), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 1))), 1)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 1))), 1), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 2))), 2)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 2))), 2), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 3))), 3)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 3))), 3), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 4))), 4)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 4))), 4), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 5))), 5)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 5))), 5), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 6))), 6)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 6))), 6), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 7))), 7)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 7))), 7), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 8))), 8)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 8))), 8), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 9))), 9)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 9))), 9), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 10))), 10)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 10))), 10), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 11))), 11)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 11))), 11), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 12))), 12)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 12))), 12), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 13))), 13)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 13))), 13), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 14))), 14)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 14))), 14), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 15))), 15)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 15))), 15), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 16))), 16)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 16))), 16), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 17))), 17)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 17))), 17), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 18))), 18)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 18))), 18), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 19))), 19)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 19))), 19), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 20))), 20)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 20))), 20), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 21))), 21)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 21))), 21), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 22))), 22)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 22))), 22), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 23))), 23)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 23))), 23), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 24))), 24)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 24))), 24), var.env_default_value)}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 25))), 25)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 25))), 25), var.env_default_value)}"
  }

  ###===================== Application Load Balancer Health check settings =====================================================###
  # The Application Load Balancer health check does not take into account the Elastic Beanstalk health check path
  # http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environments-cfg-applicationloadbalancer.html
  # http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environments-cfg-applicationloadbalancer.html#alb-default-process.config
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "${var.healthcheck_url}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Port"
    value     = "80"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Protocol"
    value     = "HTTP"
  }

  ###===================== SQS Settings =====================================================###


  setting {
      namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:sqsd" : "aws:elasticbeanstalk:customoption"}"
      name      = "${var.tier == "Worker" ? "ConnectTimeout" : "awselasticbeanstalksqsdConnectTimeout"}"
      value     = "${var.sqsd_connect_timeout}"
  }

  setting {
      namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:sqsd" : "aws:elasticbeanstalk:customoption"}"
      name      = "${var.tier == "Worker" ? "HttpConnections" : "awselasticbeanstalksqsdHttpConnections"}"
      value     = "${var.sqsd_http_connections}"
  }

  setting {
      namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:sqsd" : "aws:elasticbeanstalk:customoption"}"
      name      = "${var.tier == "Worker" ? "HttpPath" : "awselasticbeanstalksqsdHttpPath"}"
      value     = "${var.sqsd_http_path}"
  }

  setting {
      namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:sqsd" : "aws:elasticbeanstalk:customoption"}"
      name      = "${var.tier == "Worker" ? "InactivityTimeout" : "awselasticbeanstalksqsdInactivityTimeout"}"
      value     = "${var.sqsd_inactivity_timeout}"
  }

  setting {
      namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:sqsd" : "aws:elasticbeanstalk:customoption"}"
      name      = "${var.tier == "Worker" ? "MaxRetries" : "awselasticbeanstalksqsdMaxRetries"}"
      value     = "${var.sqsd_max_retries}"
  }

  setting {
      namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:sqsd" : "aws:elasticbeanstalk:customoption"}"
      name      = "${var.tier == "Worker" ? "MimeType" : "awselasticbeanstalksqsdMimeType"}"
      value     = "${var.sqsd_mime_type}"
  }

  setting {
      namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:sqsd" : "aws:elasticbeanstalk:customoption"}"
      name      = "${var.tier == "Worker" ? "RetentionPeriod" : "awselasticbeanstalksqsdRetentionPeriod"}"
      value     = "${var.sqsd_retention_period}"
  }

  setting {
      namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:sqsd" : "aws:elasticbeanstalk:customoption"}"
      name      = "${var.tier == "Worker" ? "VisibilityTimeout" : "awselasticbeanstalksqsdVisibilityTimeout"}"
      value     = "${var.sqsd_visibility_timeout}"
  }

  setting {
      namespace = "${var.tier == "Worker" ? "aws:elasticbeanstalk:sqsd" : "aws:elasticbeanstalk:customoption"}"
      name      = "${var.tier == "Worker" ? "WorkerQueueURL" : "awselasticbeanstalksqsdWorkerQueueURL"}"
      value     = "${var.sqsd_worker_queue_url}"
  }

  ###===================== Notification =====================================================###

  setting {
    namespace = "aws:elasticbeanstalk:sns:topics"
    name      = "Notification Endpoint"
    value     = "${var.notification_endpoint}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:sns:topics"
    name      = "Notification Protocol"
    value     = "${var.notification_protocol}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:sns:topics"
    name      = "Notification Topic ARN"
    value     = "${var.notification_topic_arn}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:sns:topics"
    name      = "Notification Topic Name"
    value     = "${var.notification_topic_name}"
  }
  depends_on = ["aws_security_group.default"]
}

data "aws_elb_service_account" "main" {}

data "aws_iam_policy_document" "elb_logs" {
  statement {
    sid = ""

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${local.environment_label}-logs/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["${data.aws_elb_service_account.main.arn}"]
    }

    effect = "Allow"
  }
}

resource "aws_s3_bucket" "elb_logs" {
  bucket = "${local.environment_label}-logs"
  acl    = "private"

  policy = "${data.aws_iam_policy_document.elb_logs.json}"
}

#module "tld" {
#  source    = "git::https://github.com/cloudposse/terraform-aws-route53-cluster-hostname.git?ref=tags/0.1.1"
#  namespace = "${var.namespace}"
#  name      = "${var.name}"
#  stage     = "${var.stage}"
#  zone_id   = "${var.zone_id}"
#  records   = ["${aws_elastic_beanstalk_environment.default.cname}"]
#}
