module "database" {
  source = "./database"
  schema = "fcrepo"
  host = "${aws_db_instance.db.address}"
  port = "${aws_db_instance.db.port}"
  master_username = "${aws_db_instance.db.username}"
  master_password = "${aws_db_instance.db.password}"
}

resource "null_resource" "fcrepo_database" {
  connection {
    user = "ec2-user"
    agent = true
    timeout = "3m"
    host = "${aws_instance.bastion.public_ip}"
    private_key = "${file(var.ec2_private_keyfile)}"
  }

  provisioner "remote-exec" {
    inline = [
      "${module.database.exec_script}"
    ]
  }
}

output "fcrepo_password" {
  value = "${module.database.password}"
}
