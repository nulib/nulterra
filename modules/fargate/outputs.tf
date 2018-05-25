output "lb_security_group" {
  value = "${var.load_balanced == "true" ? element(aws_security_group.this_lb_security_group.*.id, 0) : ""}"
}

output "lb_dns_name" {
  value = "${var.load_balanced == "true" ? element(aws_lb.this_load_balancer.*.dns_name, 0) : ""}"
}

output "lb_zone_id" {
  value = "${var.load_balanced == "true" ? element(aws_lb.this_load_balancer.*.zone_id, 0) : ""}"
}

output "instance_security_group" {
  value = "${aws_security_group.this_instance_security_group.id}"
}

output "cluster_name" {
  value = "${aws_ecs_cluster.this_cluster.name}"
}

output "service_name" {
  value = "${element(compact(concat(aws_ecs_service.this_service.*.name, aws_ecs_service.this_lb_service.*.name)), 0)}"
}

output "container_role" {
  value = "${aws_iam_role.task_role.name}"
}
