data "aws_ami" "pe" {
#  most_recent = true

#  filter {
#    name = "description"
#    values = ["*BYOL*"]
#  }

  filter {
    name = "name"
    values = ["Puppet*"]
  }

  filter {
    name = "owner-alias"
    values = ["aws-marketplace"]
  }

#  filter {
#    name = "platform"
#    values = ["Other Linux"]
#  }

#  filter {
#    name   = "virtualization-type"
#    values = ["hvm"]
#  }

#  filter {
#    name   = "root-device-type"
#    values = ["ebs"]
#  }

  owners = ["679593333241"] # Puppet Enterprise

  name_regex = "BYOL"

}

data "aws_iam_policy_document" "pe" {
  statement {
    sid = ""

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_instance_profile" "pe" {
  name = "${local.namespace}-pe-profile"
  role = "${aws_iam_role.pe.name}"
}

resource "aws_iam_role" "pe" {
  name               = "${local.namespace}-pe-role"
  assume_role_policy = "${data.aws_iam_policy_document.pe.json}"
}

data "aws_iam_policy_document" "pe_api_access" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["elasticfilesystem:*"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "pe_api_access" {
  name   = "${local.namespace}-pe-api-access"
  policy = "${data.aws_iam_policy_document.pe_api_access.json}"
}

resource "aws_iam_role_policy_attachment" "pe_api_access" {
  role       = "${aws_iam_role.pe.name}"
  policy_arn = "${aws_iam_policy.pe_api_access.arn}"
}

resource "aws_security_group" "pe" {
  name        = "${local.namespace}-pe"
  description = "PE Security Group"
  vpc_id      = "${module.vpc.vpc_id}"
  tags        = "${local.common_tags}"
}

resource "aws_security_group_rule" "pe_ingress" {
  security_group_id = "${aws_security_group.pe.id}"
  type              = "ingress"
  from_port         = "22"
  to_port           = "22"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "pe_egress" {
  security_group_id = "${aws_security_group.pe.id}"
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_instance" "pe" {
  ami                         = "${data.aws_ami.pe.id}"
  instance_type               = "${var.pe_instance_type}"
  key_name                    = "${var.ec2_keyname}"
  subnet_id                   = "${module.vpc.public_subnets[0]}"
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.pe.name}"
  tags                        = "${merge(local.common_tags, map("Name", "${local.namespace}-pe"))}"

  vpc_security_group_ids = [
    "${aws_security_group.pe.id}",
    "${aws_security_group.db_client.id}",
  ]

  lifecycle {
    ignore_changes = ["ami"]
  }
}

resource "null_resource" "provision_pe" {
  triggers {
    host = "${aws_instance.pe.id}"
  }

  provisioner "file" {
    connection {
      host        = "${aws_instance.pe.public_dns}"
      user        = "ec2-user"
      agent       = true
      timeout     = "3m"
      private_key = "${file(var.ec2_private_keyfile)}"
    }

    source      = "${path.module}/files/"
    destination = "/tmp/"
  }

  provisioner "remote-exec" {
    connection {
      host        = "${aws_instance.pe.public_dns}"
      user        = "ec2-user"
      agent       = true
      timeout     = "3m"
      private_key = "${file(var.ec2_private_keyfile)}"
    }

    inline = [
      "sudo mv /tmp/mount_all_efs /usr/local/sbin/mount_all_efs",
      "sudo mv /tmp/awssh /usr/local/bin/awssh",
      "sudo chmod 0755 /usr/local/bin/awssh /usr/local/sbin/mount_all_efs",
      "sudo yum install -y postgresql96 jq tmux",
    ]
  }
}

resource "aws_route53_record" "pe" {
  zone_id = "${module.dns.public_zone_id}"
  name    = "pe.${local.public_zone_name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.pe.public_ip}"]
}
