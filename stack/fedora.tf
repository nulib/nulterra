locals {
  fcrepo_db_schema = "fcrepo"
}

module "fcrepodb" {
  source          = "../modules/database"
  schema          = "${local.fcrepo_db_schema}"
  host            = "${module.db.this_db_instance_address}"
  port            = "${module.db.this_db_instance_port}"
  master_username = "${module.db.this_db_instance_username}"
  master_password = "${module.db.this_db_instance_password}"

  connection = {
    user        = "ec2-user"
    host        = "${aws_instance.bastion.public_ip}"
    private_key = "${file(var.ec2_private_keyfile)}"
  }
}

resource "aws_security_group_rule" "allow_fcrepo_postgres_access" {
  security_group_id        = "${aws_security_group.db.id}"
  type                     = "ingress"
  from_port                = "${module.db.this_db_instance_port}"
  to_port                  = "${module.db.this_db_instance_port}"
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.fcrepo_instance.id}"
}

resource "aws_s3_bucket" "fcrepo_binary_bucket" {
  bucket = "${local.namespace}-fcrepo-binaries"
  acl    = "private"
  tags   = "${local.common_tags}"
}

resource "aws_iam_user" "fcrepo_binary_bucket_user" {
  name = "${local.namespace}-fcrepo"
  path = "/system/"
}

resource "aws_iam_access_key" "fcrepo_binary_bucket_access_key" {
  user = "${aws_iam_user.fcrepo_binary_bucket_user.name}"
}

data "aws_iam_policy_document" "fcrepo_binary_bucket_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["arn:aws:s3:::*"]
  }

  statement {
    effect    = "Allow"
    actions   = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = ["${aws_s3_bucket.fcrepo_binary_bucket.arn}"]
  }

  statement {
    effect    = "Allow"
    actions   = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["${aws_s3_bucket.fcrepo_binary_bucket.arn}/*"]
  }
}

resource "aws_iam_user_policy" "fcrepo_binary_bucket_policy" {
  name   = "${local.namespace}-fcrepo-s3-bucket-access"
  user   = "${aws_iam_user.fcrepo_binary_bucket_user.name}"
  policy = "${data.aws_iam_policy_document.fcrepo_binary_bucket_access.json}"
}

data "template_file" "task_definition" {
  template = "${file("${path.module}/applications/fcrepo/service.json.tpl")}"

  vars = {
    db_host                  = "${module.db.this_db_instance_address}"
    db_port                  = "${module.db.this_db_instance_port}"
    db_user                  = "${local.fcrepo_db_schema}"
    db_password              = "${module.fcrepodb.password}"
    bucket_name              = "${aws_s3_bucket.fcrepo_binary_bucket.id}"
    bucket_access_key_id     = "${aws_iam_access_key.fcrepo_binary_bucket_access_key.id}"
    bucket_access_key_secret = "${aws_iam_access_key.fcrepo_binary_bucket_access_key.secret}"
  }
}

resource "aws_ecs_task_definition" "fcrepo_task" {
  depends_on               = ["module.fcrepodb"]
  family                   = "${local.namespace}-fcrepo-task"
  container_definitions    = "${data.template_file.task_definition.rendered}"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  network_mode             = "awsvpc"
  memory                   = "8192"
}

resource "aws_security_group" "fcrepo_lb_security_group" {
  name        = "${local.namespace}-fcrepo-lb"
  description = "Fedora Load Balancer Security Group"
  vpc_id      = "${module.vpc.vpc_id}"
  tags        = "${local.common_tags}"
}

resource "aws_security_group" "fcrepo_instance" {
  name        = "${local.namespace}-fcrepo-instance"
  description = "Fedora Load Balancer Security Group"
  vpc_id      = "${module.vpc.vpc_id}"
  tags        = "${local.common_tags}"

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = ["${aws_security_group.fcrepo_lb_security_group.id}"]
  }
}

resource "aws_ecs_cluster" "fcrepo_cluster" {
  name = "${local.namespace}-fcrepo"
}

resource "aws_lb" "fcrepo_load_balancer" {
  name            = "${local.namespace}-fcrepo-lb"
  internal        = true
  security_groups = ["${module.vpc.default_security_group_id}", "${aws_security_group.fcrepo_lb_security_group.id}"]
  subnets         = ["${module.vpc.private_subnets}"]

  tags = "${local.common_tags}"
}

resource "aws_lb_target_group" "fcrepo_target_group" {
  name        = "${local.namespace}-fcrepo-target-group"
  target_type = "ip"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${module.vpc.vpc_id}"
}

resource "aws_lb_listener" "fcrepo_listener" {
  load_balancer_arn = "${aws_lb.fcrepo_load_balancer.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.fcrepo_target_group.arn}"
    type             = "forward"
  }
}

resource "aws_ecs_service" "fcrepo_service" {
  depends_on      = ["aws_lb_listener.fcrepo_listener"]
  name            = "${local.namespace}-fcrepo-service"
  cluster         = "${aws_ecs_cluster.fcrepo_cluster.id}"
  task_definition = "${aws_ecs_task_definition.fcrepo_task.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.fcrepo_target_group.arn}"
    container_name   = "fcrepo-app"
    container_port   = 8080
  }

  network_configuration {
    subnets = ["${module.vpc.private_subnets}"]
    security_groups = ["${module.vpc.default_security_group_id}", "${aws_security_group.fcrepo_instance.id}"]
    assign_public_ip = false
  }
}

resource "aws_route53_record" "fcrepo" {
  zone_id = "${module.dns.private_zone_id}"
  name    = "fcrepo.${local.private_zone_name}"
  type    = "A"

  alias {
    name                   = "${aws_lb.fcrepo_load_balancer.dns_name}"
    zone_id                = "${aws_lb.fcrepo_load_balancer.zone_id}"
    evaluate_target_health = true
  }
}
