variable "db_master_username" {
  type = "string"
  default = "dbadmin"
}

module "db_master_password" {
  source = "../password"
}

module "db" {
  source = "terraform-aws-modules/rds/aws"
  version = "1.9.0"

  identifier = "${var.stack_name}-db"

  engine            = "postgres"
  engine_version    = "9.6.6"

  instance_class    = "db.t2.medium"
  allocated_storage = 5

  name     = "${var.stack_name}db"
  username = "${var.db_master_username}"
  password = "${module.db_master_password.result}"
  port     = 5432

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  vpc_security_group_ids = ["${aws_security_group.db.id}"]

  tags = "${local.common_tags}"

  subnet_ids = ["${module.vpc.private_subnets}"]

  family = "postgres9.6"

  parameters = [
    {
      name = "client_encoding"
      value = "UTF8"
    }
  ]
}

resource "aws_security_group" "db_client" {
  name = "${var.stack_name}-db-client"
  description = "RDS Client Security Group"
  vpc_id = "${module.vpc.vpc_id}"
  tags = "${local.common_tags}"
}

resource "aws_security_group" "db" {
  name = "${var.stack_name}-db"
  description = "RDS Security Group"
  vpc_id = "${module.vpc.vpc_id}"
  tags = "${local.common_tags}"

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = ["${aws_security_group.db_client.id}"]
  }
}
