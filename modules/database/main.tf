variable "schema" {
  type = string
}

variable "host" {
  type = string
}

variable "port" {
  type = string
}

variable "master_username" {
  type = string
}

variable "master_password" {
  type = string
}

variable "connection" {
  type = map(string)
}

variable "dependency_id" {
  default = ""
}

module "role_password" {
  source = "../password"
}

locals {
  create_script = <<EOF
DO
\$do\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${var.schema}') THEN
    CREATE ROLE ${var.schema};
  END IF;
  ALTER ROLE ${var.schema} WITH LOGIN ENCRYPTED PASSWORD '${module.role_password.result}';
  IF NOT EXISTS (
    SELECT FROM pg_catalog.pg_auth_members a
      JOIN pg_catalog.pg_roles b ON a.roleid = b.oid
      JOIN pg_catalog.pg_roles c ON a.member = c.oid
      WHERE c.rolname = '${var.master_username}' AND b.rolname = '${var.schema}'
  ) THEN
    GRANT ${var.schema} TO ${var.master_username};
  END IF;
END
\$do\$;
CREATE DATABASE ${var.schema} OWNER ${var.schema};
EOF


  destroy_script = <<EOF
DO
$do$
BEGIN
  DROP DATABASE ${var.schema};
  DROP ROLE ${var.schema};
END
$do$;
EOF


  psql            = "PGPASSWORD='${var.master_password}' psql -U ${var.master_username} -h ${var.host} -p ${var.port} postgres"
  create_command  = "echo \"${local.create_script}\" | ${local.psql}"
  destroy_command = "echo \"${local.destroy_script}\" | ${local.psql}"
}

resource "null_resource" "this_database" {
  triggers = {
    value = var.host
  }

  connection {
    user        = var.connection["user"]
    host        = var.connection["host"]
    private_key = var.connection["private_key"]
    agent       = true
    timeout     = "3m"
  }

  provisioner "remote-exec" {
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibility in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    inline = [local.create_command]
  }

  #  provisioner "remote-exec" {
  #    inline = ["${local.destroy_command}"]
  #    when   = "destroy"
  #  }

  lifecycle {
    create_before_destroy = true
  }
}

# The empty string reference below is just to prevent things that depend on the
# password from using it until after the provisioner runs.
output "password" {
  value = "${module.role_password.result}${null_resource.this_database.id == "" ? "" : ""}"
}

