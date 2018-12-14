#output "host" {
#  value       = "${module.tld.hostname}"
#  description = "DNS hostname"
#}

output "name" {
  value       = "${element(coalescelist(aws_elastic_beanstalk_environment.default.*.name, aws_elastic_beanstalk_environment.worker.*.name), 0)}"
  description = "Name"
}

output "security_group_id" {
  value       = "${aws_security_group.default.id}"
  description = "Security group id"
}

output "elb_name" {
  value       = "${element(flatten(concat(aws_elastic_beanstalk_environment.default.*.load_balancers, aws_elastic_beanstalk_environment.worker.*.load_balancers, list(list("no-elb")))), 0)}"
  description = "ELB name"
}

output "elb_dns_name" {
  value       = "${element(coalescelist(aws_elastic_beanstalk_environment.default.*.cname, aws_elastic_beanstalk_environment.worker.*.cname), 0)}"
  description = "ELB technical host"
}

output "elb_zone_id" {
  value       = "${var.alb_zone_id[data.aws_region.default.name]}"
  description = "ELB zone id"
}

output "ec2_instance_profile_role_name" {
  value       = "${aws_iam_role.ec2.name}"
  description = "Instance IAM role name"
}

output "autoscaling_groups" {
  value       = "${flatten(coalescelist(aws_elastic_beanstalk_environment.default.*.autoscaling_groups, aws_elastic_beanstalk_environment.worker.*.autoscaling_groups))}"
  description = "Auto Scaling Group"
}
