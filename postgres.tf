variable "db_master_username" {
  type = "string"
  default = "dbadmin"
}

module "db_master_password" {
  source = "./password"
}

resource "aws_db_subnet_group" "db_subnet_group" {
  subnet_ids = [
    "${aws_subnet.private_subnet_a.id}",
    "${aws_subnet.private_subnet_b.id}", 
    "${aws_subnet.private_subnet_c.id}"
  ]
  tags = "${local.common_tags}"
}

resource "aws_db_instance" "db" {
  name = "${var.stack_name}-db"
  engine = "postgres"
  instance_class = "db.t2.medium"
  allocated_storage = 5
  db_subnet_group_name = "${aws_db_subnet_group.db_subnet_group.name}"
  username = "${var.db_master_username}"
  password = "${module.db_master_password.result}"
  vpc_security_group_ids = ["${aws_security_group.db.id}"]
  skip_final_snapshot = true
  tags = "${local.common_tags}"
}

resource "aws_security_group" "db_client" {
  name = "${var.stack_name}-db-client"
  description = "RDS Client Security Group"
  vpc_id = "${aws_vpc.vpc.id}"
  tags = "${local.common_tags}"
}

resource "aws_security_group" "db" {
  name = "${var.stack_name}-db"
  description = "RDS Security Group"
  vpc_id = "${aws_vpc.vpc.id}"
  tags = "${local.common_tags}"

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = ["${aws_security_group.db_client.id}"]
  }
}

output "db_host" {
  value = "${aws_db_instance.db.address}"
}

output "db_port" {
  value = "${aws_db_instance.db.port}"
}

output "db_user" {
  value = "${aws_db_instance.db.username}"
}

output "db_password" {
  value = "${aws_db_instance.db.password}"
}
