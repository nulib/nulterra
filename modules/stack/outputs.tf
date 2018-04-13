output "db_address" {
  value = "${module.db.this_db_instance_address}"
}

output "db_port" {
  value = "${module.db.this_db_instance_port}"
}

output "db_master_username" {
  value = "${module.db.this_db_instance_username}"
}

output "db_master_password" {
  value = "${module.db.this_db_instance_password}"
}

output "bastion_address" {
  value = "${aws_route53_record.bastion.name}"
}

output "redis_address" {
  value = "${aws_route53_record.redis.name}"
}

output "redis_port" {
  value = "${aws_elasticache_cluster.redis.cache_nodes.0.port}"
}
