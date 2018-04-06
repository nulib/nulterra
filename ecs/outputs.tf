output "security_group" {
  value = "${module.ecs_instances.ecs_instance_security_group_id}"
}

output "client_security_group" {
  value = "${aws_security_group.this_client_security_group.id}"
}

output "lb_endpoint" {
  value = "${aws_elb.this_elb.dns_name}"
}

output "lb_zone_id" {
  value = "${aws_elb.this_elb.zone_id}"
}
