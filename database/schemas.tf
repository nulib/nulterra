variable "schema"              { type = "string" }
variable "host"                { type = "string" }
variable "port"                { type = "string" }
variable "master_username"     { type = "string" }
variable "master_password"     { type = "string" }
variable "connection"          { type = "map"    }

module "role_password" {
  source = "../password"
}

locals {
  create_script = <<EOF
CREATE ROLE ${var.schema} WITH LOGIN ENCRYPTED PASSWORD '${module.role_password.result}';
GRANT ${var.schema} TO ${var.master_username};
CREATE DATABASE ${var.schema} OWNER ${var.schema};
EOF
  destroy_script = <<EOF
DROP DATABASE ${var.schema};
DROP ROLE ${var.schema};
EOF
  psql = "PGPASSWORD='${var.master_password}' psql -U ${var.master_username} -h ${var.host} -p ${var.port} postgres"
  create_command  = "echo \"${local.create_script}\" | ${local.psql}"
  destroy_command = "echo \"${local.destroy_script}\" | ${local.psql}"
}

resource "null_resource" "this_database" {
  triggers {
    value = "${var.host}"
  }

  connection {
    user = "${var.connection["user"]}"
    host = "${var.connection["host"]}"
    private_key = "${var.connection["private_key"]}"
    agent = true
    timeout = "3m"
  }

  provisioner "remote-exec" {
    inline = ["${local.create_command}"]
  }

#  provisioner "remote-exec" {
#    inline = ["${local.destroy_command}"]
#    when   = "destroy"
#  }

  lifecycle {
    create_before_destroy = true
  }
}

output "password" {
  value = "${module.role_password.result}"
}
