resource "aws_vpc" "vpc" {
  cidr_block           = "${var.subnet_config["vpc"]}"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = "${merge(local.common_tags, map("Name", var.stack_name))}"
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.subnet_config["public_subnet_a"]}"
  availability_zone = "${var.azs[0]}"

  tags = "${merge(local.common_tags, map("Name", "${var.stack_name}-public-a"))}"
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.subnet_config["public_subnet_b"]}"
  availability_zone = "${var.azs[1]}"

  tags = "${merge(local.common_tags, map("Name", "${var.stack_name}-public-b"))}"
}

resource "aws_subnet" "public_subnet_c" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.subnet_config["public_subnet_c"]}"
  availability_zone = "${var.azs[2]}"

  tags = "${merge(local.common_tags, map("Name", "${var.stack_name}-public-c"))}"
}

resource "aws_internet_gateway" "public_gateway" {
  vpc_id = "${aws_vpc.vpc.id}"
  depends_on = [
    "aws_route_table_association.public_subnet_a_route_table_association",
    "aws_route_table_association.public_subnet_b_route_table_association",
    "aws_route_table_association.public_subnet_c_route_table_association"
  ]
  tags = "${local.common_tags}"
}

resource "aws_route_table" "public_route_table" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = "${local.common_tags}"
}

resource "aws_route" "public_route" {
  route_table_id = "${aws_route_table.public_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.public_gateway.id}"
}

resource "aws_route_table_association" "public_subnet_a_route_table_association" {
  route_table_id = "${aws_route_table.public_route_table.id}"
  subnet_id = "${aws_subnet.public_subnet_a.id}"
}

resource "aws_route_table_association" "public_subnet_b_route_table_association" {
  route_table_id = "${aws_route_table.public_route_table.id}"
  subnet_id = "${aws_subnet.public_subnet_b.id}"
}

resource "aws_route_table_association" "public_subnet_c_route_table_association" {
  route_table_id = "${aws_route_table.public_route_table.id}"
  subnet_id = "${aws_subnet.public_subnet_c.id}"
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.subnet_config["private_subnet_a"]}"
  availability_zone = "${var.azs[0]}"

  tags = "${merge(local.common_tags, map("Name", "${var.stack_name}-private-a"))}"
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.subnet_config["private_subnet_b"]}"
  availability_zone = "${var.azs[1]}"

  tags = "${merge(local.common_tags, map("Name", "${var.stack_name}-private-b"))}"
}

resource "aws_subnet" "private_subnet_c" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.subnet_config["private_subnet_c"]}"
  availability_zone = "${var.azs[2]}"

  tags = "${merge(local.common_tags, map("Name", "${var.stack_name}-private-c"))}"
}

resource "aws_eip" "nat_ip" {
  vpc = true
  tags = "${local.common_tags}"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat_ip.id}"
  subnet_id = "${aws_subnet.public_subnet_a.id}"
  tags = "${local.common_tags}"
}

resource "aws_route_table" "private_route_table" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = "${local.common_tags}"
}

resource "aws_route" "private_route" {
  route_table_id = "${aws_route_table.private_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.nat.id}"
}

resource "aws_route_table_association" "private_subnet_a_route_table_association" {
  route_table_id = "${aws_route_table.private_route_table.id}"
  subnet_id = "${aws_subnet.private_subnet_a.id}"
}

resource "aws_route_table_association" "private_subnet_b_route_table_association" {
  route_table_id = "${aws_route_table.private_route_table.id}"
  subnet_id = "${aws_subnet.private_subnet_b.id}"
}

resource "aws_route_table_association" "private_subnet_c_route_table_association" {
  route_table_id = "${aws_route_table.private_route_table.id}"
  subnet_id = "${aws_subnet.private_subnet_c.id}"
}

data "aws_route53_zone" "hosted_zone" {
  name = "${var.hosted_zone_name}"
}

resource "aws_route53_zone" "public_zone" {
  name = "${var.stack_name}.${var.hosted_zone_name}."
  vpc_id = "${aws_vpc.vpc.id}"
  vpc_region = "${var.aws_region}"
  tags = "${local.common_tags}"
}

resource "aws_route53_record" "public_zone" {
  zone_id = "${data.aws_route53_zone.hosted_zone.id}"
  type = "NS"
  name = "${aws_route53_zone.public_zone.name}"
  ttl = 300
  records = [
    "${aws_route53_zone.public_zone.name_servers.0}",
    "${aws_route53_zone.public_zone.name_servers.1}",
    "${aws_route53_zone.public_zone.name_servers.2}",
    "${aws_route53_zone.public_zone.name_servers.3}"
  ]
}
