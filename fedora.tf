module "database" {
  source = "./database"
  schema = "fcrepo"
  host = "${module.db.address}"
  port = "${module.db.port}"
  master_username = "${aws_db_instance.db.username}"
  master_password = "${aws_db_instance.db.password}"
}

resource "null_resource" "fcrepo_database" {
  triggers {
    db = "${aws_db_instance.db.id}"
  }

  connection {
    user = "ec2-user"
    agent = true
    timeout = "3m"
    host = "${aws_instance.bastion.public_ip}"
    private_key = "${file(var.ec2_private_keyfile)}"
  }

  provisioner "remote-exec" {
    inline = [
      "${module.database.exec_script}"
    ]
  }
}

resource "aws_s3_bucket" "fcrepo_binary_bucket" {
  bucket = "${var.stack_name}-fcrepo-binaries"
  acl = "private"
  tags = "${local.common_tags}"
}

resource "aws_iam_user" "fcrepo_binary_bucket_user" {
  name = "${var.stack_name}-fcrepo"
  path = "/system/"
}

resource "aws_iam_access_key" "fcrepo_binary_bucket_access_key" {
  user = "${aws_iam_user.fcrepo_binary_bucket_user.name}"
}

resource "aws_iam_user_policy" "fcrepo_binary_bucket_policy" {
  name = "${var.stack_name}-fcrepo-s3-bucket-access"
  user = "${aws_iam_user.fcrepo_binary_bucket_user.name}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:ListAllMyBuckets"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::*"
    },
    {
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.fcrepo_binary_bucket.arn}"
    },
    {
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.fcrepo_binary_bucket.arn}/*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "fcrepo" {
  name = "${var.stack_name}-fcrepo"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_elb" "fcrepo" {
  name = "${var.stack_name}-fcrepo-lb"
  availability_zones = "${var.azs}"
  internal = true
  cross_zone_load_balancing = true
  connection_draining = true
  subnets = [
    "${aws_subnet.private_subnet_a.id}",
    "${aws_subnet.private_subnet_b.id}",
    "${aws_subnet.private_subnet_c.id}"
  ]

  listener {
    instance_port = 8080
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:8080/rest"
    interval = 30
  }

  tags = "${local.common_tags}"
}

resource "aws_ecs_task_definition" "fcrepo_service" {
  family = "fcrepo-service"
  container_definitions = "${file("ecs/fcrepo_server.json")}"
  requires_compatibilities = ["EC2"]
}

resource "aws_ecs_cluster" "fcrepo" {
  name = "${var.stack_name}-fcrepo"
}

resource "aws_ecs_service" "fcrepo" {
  name = "${var.stack_name}-fcrepo"
  cluster = "${aws_ecs_cluster.fcrepo.id}"
  task_definition = "${aws_ecs_task_definition.fcrepo_service.arn}"
  desired_count = 1
  iam_role = "${aws_iam_role.fcrepo.arn}"

  load_balancer {
    elb_name = "${aws_elb.fcrepo.name}"
    container_name = "fcrepo"
    container_port = "8080"
  }
}

output "fcrepo_password" {
  value = "${module.database.password}"
}
