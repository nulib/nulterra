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
  description = "Bastion Host Security Group"
  vpc_id = "${aws_vpc.vpc.id}"

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
  vpc_security_group_ids = ["${aws_security_group.bastion.id}", "${aws_security_group.db_client.id}"]
  subnet_id = "${aws_subnet.PublicSubnetA.id}"
  associate_public_ip_address = true
  tags = "${local.common_tags}"
}

resource "null_resource" "postgres_client" {
  connection {
    user = "ec2-user"
    agent = true
    timeout = "3m"
    host = "${aws_instance.bastion.public_ip}"
    private_key = "${file("/Users/mbk836/.ssh/id_rsa")}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y postgresql96"
    ]
  }
}
