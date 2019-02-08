module "db_master_password" {
  source = "../modules/password"
}

data "aws_db_instance" "existing_database" {
  db_instance_identifier = "${local.namespace}-db"
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "1.9.0"

  identifier = "${local.namespace}-db"

  engine         = "postgres"
  engine_version = "${data.aws_db_instance.existing_database.engine_version}"

  instance_class    = "db.t2.medium"
  allocated_storage = 100

  name     = "${var.stack_name}db"
  username = "${var.db_master_username}"
  password = "${module.db_master_password.result}"
  port     = 5432

  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = 35
  copy_tags_to_snapshot   = true

  vpc_security_group_ids = ["${aws_security_group.db.id}"]

  tags = "${local.common_tags}"

  subnet_ids = ["${module.vpc.private_subnets}"]

  family = "postgres9.6"

  parameters = [
    {
      name  = "client_encoding"
      value = "UTF8"
    },
  ]
}

resource "aws_security_group" "db_client" {
  name        = "${local.namespace}-db-client"
  description = "RDS Client Security Group"
  vpc_id      = "${module.vpc.vpc_id}"
  tags        = "${local.common_tags}"
}

resource "aws_security_group" "db" {
  name        = "${local.namespace}-db"
  description = "RDS Security Group"
  vpc_id      = "${module.vpc.vpc_id}"
  tags        = "${local.common_tags}"
}

resource "aws_security_group_rule" "db_client_access" {
  security_group_id        = "${aws_security_group.db.id}"
  type                     = "ingress"
  from_port                = "5432"
  to_port                  = "5432"
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.db_client.id}"
}
