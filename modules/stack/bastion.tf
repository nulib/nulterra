data "aws_ami" "amzn" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["137112412989"] # Amazon
}

resource "aws_security_group" "bastion" {
  name = "${var.stack_name}-bastion"
  description = "Bastion Host Security Group"
  vpc_id = "${module.vpc.vpc_id}"
  tags = "${local.common_tags}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "bastion" {
  ami = "${data.aws_ami.amzn.id}"
  instance_type = "t2.nano"
  key_name = "${var.ec2_keyname}"
  vpc_security_group_ids = [
    "${aws_security_group.bastion.id}",
    "${aws_security_group.db_client.id}"
  ]
  subnet_id = "${module.vpc.public_subnets[0]}"
  associate_public_ip_address = true
  tags = "${merge(local.common_tags, map("Name", "${var.stack_name}-bastion"))}"

  provisioner "remote-exec" {
    connection {
      user = "ec2-user"
      agent = true
      timeout = "3m"
      private_key = "${file(var.ec2_private_keyfile)}"
    }

    inline = [
      "sudo yum install -y postgresql96"
    ]
  }
}

resource "aws_route53_record" "bastion" {
  zone_id = "${module.dns.public_zone_id}"
  name    = "bastion.${local.public_zone_name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.bastion.public_ip}"]
}
