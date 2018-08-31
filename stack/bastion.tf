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

data "aws_iam_policy_document" "bastion" {
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

resource "aws_iam_instance_profile" "bastion" {
  name = "${local.namespace}-bastion-profile"
  role = "${aws_iam_role.bastion.name}"
}

resource "aws_iam_role" "bastion" {
  name               = "${local.namespace}-bastion-role"
  assume_role_policy = "${data.aws_iam_policy_document.bastion.json}"
}

data "aws_iam_policy_document" "bastion_api_access" {
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

resource "aws_iam_policy" "bastion_api_access" {
  name   = "${local.namespace}-bastion-api-access"
  policy = "${data.aws_iam_policy_document.bastion_api_access.json}"
}

resource "aws_iam_role_policy_attachment" "bastion_api_access" {
  role       = "${aws_iam_role.bastion.name}"
  policy_arn = "${aws_iam_policy.bastion_api_access.arn}"
}

resource "aws_security_group" "bastion" {
  name        = "${local.namespace}-bastion"
  description = "Bastion Host Security Group"
  vpc_id      = "${module.vpc.vpc_id}"
  tags        = "${local.common_tags}"
}

resource "aws_security_group_rule" "bastion_ingress" {
  security_group_id = "${aws_security_group.bastion.id}"
  type              = "ingress"
  from_port         = "22"
  to_port           = "22"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion_egress" {
  security_group_id = "${aws_security_group.bastion.id}"
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_instance" "bastion" {
  ami                         = "${data.aws_ami.amzn.id}"
  instance_type               = "${var.bastion_instance_type}"
  key_name                    = "${var.ec2_keyname}"
  subnet_id                   = "${module.vpc.public_subnets[0]}"
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.bastion.name}"
  tags                        = "${merge(local.common_tags, map("Name", "${local.namespace}-bastion"))}"

  vpc_security_group_ids = [
    "${aws_security_group.bastion.id}",
    "${aws_security_group.db_client.id}",
  ]
}

resource "null_resource" "provision_bastion" {
  triggers {
    host = "${aws_instance.bastion.id}"
  }

  provisioner "file" {
    connection {
      host        = "${aws_instance.bastion.public_dns}"
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
      host        = "${aws_instance.bastion.public_dns}"
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

resource "aws_route53_record" "bastion" {
  zone_id = "${module.dns.public_zone_id}"
  name    = "bastion.${local.public_zone_name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.bastion.public_ip}"]
}
