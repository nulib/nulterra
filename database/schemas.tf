variable "schema" {
  type = "string"
}

variable "host" {
  type = "string"
}

variable "port" {
  type = "string"
}

variable "master_username" {
  type = "string"
}

variable "master_password" {
  type = "string"
}

module "role_password" {
  source = "../password"
}

locals {
  db_script = <<EOF
CREATE ROLE ${var.schema} WITH LOGIN ENCRYPTED PASSWORD '${module.role_password.result}';
GRANT ${var.schema} TO ${var.master_username};
CREATE DATABASE ${var.schema} OWNER ${var.schema};
EOF
  exec_script = "echo \"${local.db_script}\" | PGPASSWORD='${var.master_password}' psql -U ${var.master_username} -h ${var.host} -p ${var.port} postgres"
}

output "password" {
  value = "${module.role_password.result}"
}

output "exec_script" {
  value = "${local.exec_script}"
}
