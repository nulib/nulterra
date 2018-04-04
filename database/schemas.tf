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

provider "postgresql" {
  alias = "rds"
  host = "${var.host}"
  port = "${var.port}"
  username = "${var.master_username}"
  password = "${var.master_password}"
  sslmode = "require"
}

resource "postgresql_role" "role" {
  provider = "postgresql.rds"
  name = "${var.schema}"
  login = true
  password = "${module.role_password.result}"
}

resource "postgresql_database" "db" {
  provider = "postgresql.rds"
  name = "${var.schema}"
  owner = "${postgresql_role.role.name}"
}

output "password" {
  value = "${module.role_password.result}"
}
