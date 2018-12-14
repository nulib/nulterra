#
# Full list of options:
# http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/command-options-general.html#command-options-general-elasticbeanstalkmanagedactionsplatformupdate
#
resource "aws_elastic_beanstalk_environment" "default" {
  count         = "${var.tier == "Worker" ? 0 : 1}"
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
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "BlockDeviceMappings"
    value     = "${var.extra_block_devices}"
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
    namespace = "aws:elb:loadbalancer"
    name      = "CrossZone"
    value     = "true"
  }
  setting {
    namespace = "aws:elb:listener"
    name      = "ListenerProtocol"
    value     = "HTTP"
  }
  setting {
    namespace = "aws:elb:listener"
    name      = "InstancePort"
    value     = "${var.instance_port}"
  }
  setting {
    namespace = "aws:elb:listener"
    name      = "ListenerEnabled"
    value     = "${var.http_listener_enabled  == "true" || var.loadbalancer_certificate_arn == "" ? "true" : "false"}"
  }
  setting {
    namespace = "aws:elb:listener:443"
    name      = "ListenerProtocol"
    value     = "HTTPS"
  }
  setting {
    namespace = "aws:elb:listener:443"
    name      = "InstancePort"
    value     = "${var.instance_port}"
  }
  setting {
    namespace = "aws:elb:listener:443"
    name      = "InstanceProtocol"
    value     = "HTTP"
  }
  setting {
    namespace = "aws:elb:listener:443"
    name      = "SSLCertificateId"
    value     = "${var.loadbalancer_certificate_arn}"
  }
  setting {
    namespace = "aws:elb:listener:443"
    name      = "ListenerEnabled"
    value     = "${var.loadbalancer_certificate_arn == "" ? "false" : "true"}"
  }
  setting {
    namespace = "aws:elb:policies"
    name      = "ConnectionDrainingEnabled"
    value     = "true"
  }
  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "AccessLogsS3Bucket"
    value     = "${aws_s3_bucket.elb_logs.id}"
  }
  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "AccessLogsS3Enabled"
    value     = "true"
  }
  setting {
    namespace = "aws:elbv2:listener:default"
    name      = "ListenerEnabled"
    value     = "${var.http_listener_enabled == "true" || var.loadbalancer_certificate_arn == "" ? "true" : "false"}"
  }
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "ListenerEnabled"
    value     = "${var.loadbalancer_certificate_arn == "" ? "false" : "true"}"
  }
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "Protocol"
    value     = "HTTPS"
  }
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLCertificateArns"
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
    value     = "${var.managed_actions_enabled}"
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
