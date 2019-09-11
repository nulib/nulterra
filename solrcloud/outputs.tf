output "exhibitor_endpoint" {
  value = "http://${aws_route53_record.zookeeper.name}/exhibitor/v1/ui/index.html"
}

output "security_groups" {
  value = {
    index     = "${module.solr_environment.security_group_id}"
    zookeeper = "${module.zookeeper_environment.security_group_id}"
  }
}

output "index_endpoint" {
  value = "http://${aws_route53_record.solr.name}/solr/"
}

output "zookeeper_address" {
  value = "zk.${local.private_zone_name}"
}

output "zookeeper_port" {
  value = "2181"
}
