resource "aws_vpc" "vpc" {
  cidr_block           = "${var.subnet_config["VPC"]}"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = "${local.common_tags}"
}

resource "aws_subnet" "PublicSubnetA" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.subnet_config["PublicSubnetA"]}"
  availability_zone = "${var.azs[0]}"

  tags = "${merge(local.common_tags, map(
            "Name", "Public Subnet A"
          ))}"
}

resource "aws_subnet" "PublicSubnetB" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.subnet_config["PublicSubnetB"]}"
  availability_zone = "${var.azs[1]}"

  tags = "${merge(local.common_tags, map(
            "Name", "Public Subnet B"
          ))}"
}

resource "aws_subnet" "PublicSubnetC" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.subnet_config["PublicSubnetC"]}"
  availability_zone = "${var.azs[2]}"

  tags = "${merge(local.common_tags, map(
            "Name", "Public Subnet C"
          ))}"
}

resource "aws_internet_gateway" "InternetGateway" {
  vpc_id = "${aws_vpc.vpc.id}"
  depends_on = [
    "aws_route_table_association.PublicSubnetARouteTableAssociation",
    "aws_route_table_association.PublicSubnetBRouteTableAssociation",
    "aws_route_table_association.PublicSubnetCRouteTableAssociation"
  ]
}

resource "aws_route_table" "PublicRouteTable" {
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_route" "PublicRoute" {
  route_table_id = "${aws_route_table.PublicRouteTable.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.InternetGateway.id}"
}

resource "aws_route_table_association" "PublicSubnetARouteTableAssociation" {
  route_table_id = "${aws_route_table.PublicRouteTable.id}"
  subnet_id = "${aws_subnet.PublicSubnetA.id}"
}

resource "aws_route_table_association" "PublicSubnetBRouteTableAssociation" {
  route_table_id = "${aws_route_table.PublicRouteTable.id}"
  subnet_id = "${aws_subnet.PublicSubnetB.id}"
}

resource "aws_route_table_association" "PublicSubnetCRouteTableAssociation" {
  route_table_id = "${aws_route_table.PublicRouteTable.id}"
  subnet_id = "${aws_subnet.PublicSubnetC.id}"
}

resource "aws_subnet" "PrivateSubnetA" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.subnet_config["PrivateSubnetA"]}"
  availability_zone = "${var.azs[0]}"

  tags = "${merge(local.common_tags, map(
            "Name", "Private Subnet A"
          ))}"
}

resource "aws_subnet" "PrivateSubnetB" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.subnet_config["PrivateSubnetB"]}"
  availability_zone = "${var.azs[1]}"

  tags = "${merge(local.common_tags, map(
            "Name", "Private Subnet B"
          ))}"
}

resource "aws_subnet" "PrivateSubnetC" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.subnet_config["PrivateSubnetC"]}"
  availability_zone = "${var.azs[2]}"

  tags = "${merge(local.common_tags, map(
            "Name", "Private Subnet C"
          ))}"
}

resource "aws_eip" "NATEIP" {
  vpc = true
}

resource "aws_nat_gateway" "NAT" {
  allocation_id = "${aws_eip.NATEIP.id}"
  subnet_id = "${aws_subnet.PublicSubnetA.id}"
}

resource "aws_route_table" "PrivateRouteTable" {
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_route" "PrivateRoute" {
  route_table_id = "${aws_route_table.PrivateRouteTable.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.NAT.id}"
}

resource "aws_route_table_association" "PrivateSubnetARouteTableAssociation" {
  route_table_id = "${aws_route_table.PrivateRouteTable.id}"
  subnet_id = "${aws_subnet.PrivateSubnetA.id}"
}

resource "aws_route_table_association" "PrivateSubnetBRouteTableAssociation" {
  route_table_id = "${aws_route_table.PrivateRouteTable.id}"
  subnet_id = "${aws_subnet.PrivateSubnetB.id}"
}

resource "aws_route_table_association" "PrivateSubnetCRouteTableAssociation" {
  route_table_id = "${aws_route_table.PrivateRouteTable.id}"
  subnet_id = "${aws_subnet.PrivateSubnetC.id}"
}

resource "aws_route53_zone" "DNS" {
  name = "${var.hosted_zone_name}."
  vpc_id = "${aws_vpc.vpc.id}"
  vpc_region = "${var.aws_region}"
  tags = "${local.common_tags}"
}
