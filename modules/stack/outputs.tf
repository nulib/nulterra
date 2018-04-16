output "bastion_address" {
  value = "${aws_route53_record.bastion.name}"
}

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

output "repo_endpoint" {
  value = "http://${aws_route53_record.fcrepo.name}/rest"
}

output "index_endpoint" {
  value = "http://${aws_route53_record.solr.name}/solr/"
}

output "iiif_endpoint" {
  value = "http://${element(concat(aws_cloudfront_distribution.cantaloupe.*.domain_name, list(aws_route53_record.cantaloupe.name)), 0)}/iiif/2"
}

output "cache_address" {
  value = "${aws_route53_record.redis.name}"
}

output "cache_port" {
  value = "${aws_elasticache_cluster.redis.cache_nodes.0.port}"
}

output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "public_subnets" {
  value = "${module.vpc.public_subnets}"
}

output "private_subnets" {
  value = "${module.vpc.private_subnets}"
}
