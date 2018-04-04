module "database" {
  source = "./database"
  schema = "fcrepo"
  host = "${aws_db_instance.db.address}"
  port = "${aws_db_instance.db.port}"
  master_username = "${aws_db_instance.db.username}"
  master_password = "${aws_db_instance.db.password}"
}

output "fcrepo_password" {
  value = "${module.database.password}"
}
