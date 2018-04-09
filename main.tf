terraform {
  backend "s3" {}
}

module "stack" {
  source = "./stack"

  stack_name = "${var.stack_name}"
  project_name = "${var.project_name}"
  hosted_zone_name = "${var.hosted_zone_name}"
  ec2_keyname = "${var.ec2_keyname}"
  ec2_private_keyfile = "${var.ec2_private_keyfile}"
  tags = "${var.tags}"
}

output "db_address" {
  value = "${module.stack.db_address}"
}

output "db_port" {
  value = "${module.stack.db_port}"
}

output "db_master_username" {
  value = "${module.stack.db_master_username}"
}

output "db_master_password" {
  value = "${module.stack.db_master_password}"
}

output "bastion_address" {
  value = "${module.stack.bastion_address}"
}
