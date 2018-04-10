data "aws_ami" "ecs_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-2017.09.k-amazon-ecs-optimized"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["591542846629"] # Amazon
}

resource "aws_iam_role" "this_role" {
  name = "${var.name}"
  assume_role_policy = "${data.aws_iam_policy_document.container_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "this_container_policy" {
  role = "${aws_iam_role.this_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "this_container_permissions" {
  role = "${aws_iam_role.this_role.name}"
  policy_arn = "${aws_iam_policy.ecs_service_permissions.arn}"
}

resource "aws_security_group" "this_client_security_group" {
  name = "${var.name}-client"
  description = "${var.name} Client Security Group"
  vpc_id = "${var.vpc_id}"
  tags = "${merge(var.tags, map("Name", "${var.name}-client"))}"
}

resource "aws_security_group" "this_lb_security_group" {
  name = "${var.name}-lb"
  description = "${var.name} Security Group"
  vpc_id = "${var.vpc_id}"
  tags = "${merge(var.tags, map("Name", "${var.name}-lb"))}"

  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "this_lb_security_group_rule" {
  count     = "${length(var.client_access)}"
  type      = "ingress"
  from_port = "${lookup(var.client_access[count.index], "from_port")}"
  to_port   = "${lookup(var.client_access[count.index], "to_port")}"
  protocol  = "${lookup(var.client_access[count.index], "protocol")}"

  source_security_group_id = "${aws_security_group.this_client_security_group.id}"

  security_group_id = "${aws_security_group.this_lb_security_group.id}"
}

resource "aws_security_group_rule" "this_cidr_rule" {
  count       = "${length(var.cidr_access)}"
  type        = "ingress"
  from_port   = "${lookup(var.cidr_access[count.index], "from_port")}"
  to_port     = "${lookup(var.cidr_access[count.index], "to_port")}"
  protocol    = "${lookup(var.cidr_access[count.index], "protocol")}"
  cidr_blocks = ["${lookup(var.cidr_access[count.index], "cidr")}"]

  security_group_id = "${aws_security_group.this_lb_security_group.id}"
}

resource "aws_elb" "this_elb" {
  name = "${var.name}-lb"
  internal = true
  cross_zone_load_balancing = true
  connection_draining = true
  subnets = ["${var.subnets}"]
  security_groups = ["${aws_security_group.this_lb_security_group.id}"]

  listener {
    instance_port = "${var.instance_port}"
    instance_protocol = "${var.instance_protocol}"
    lb_port = "${var.lb_port}"
    lb_protocol = "${var.lb_protocol}"
  }

  health_check {
    target = "${var.health_check_target}"
    healthy_threshold = "${var.health_check_healthy_threshold}"
    unhealthy_threshold = "${var.health_check_unhealthy_threshold}"
    timeout = "${var.health_check_timeout}"
    interval = "${var.health_check_interval}"
  }

  tags = "${var.tags}"
}

resource "aws_security_group_rule" "lb_access_to_client" {
  type = "ingress"
  from_port = "${var.instance_port}"
  to_port   = "${var.instance_port}"
  protocol  = "tcp"
  source_security_group_id = "${aws_security_group.this_lb_security_group.id}"
  security_group_id = "${module.ecs_instances.ecs_instance_security_group_id}"
}

resource "aws_ecs_task_definition" "this_task_definition" {
  family = "${var.name}-service"
  container_definitions = "${var.container_definitions}"
  requires_compatibilities = ["EC2"]
}

resource "aws_ecs_cluster" "this_cluster" {
  name = "${var.name}"
}

resource "aws_ecs_service" "this_service" {
  name = "${var.name}"
  cluster = "${aws_ecs_cluster.this_cluster.id}"
  task_definition = "${aws_ecs_task_definition.this_task_definition.arn}"
  desired_count = "${var.desired_capacity}"
  iam_role = "${aws_iam_role.this_role.arn}"

  load_balancer {
    elb_name = "${aws_elb.this_elb.name}"
    container_name = "${var.name}"
    container_port = "${var.instance_port}"
  }
}

resource "aws_iam_instance_profile" "this_instance_profile" {
  name = "${var.name}-profile"
  role = "${aws_iam_role.this_role.name}"
}

module "ecs_instances" {
  source = "git://github.com/arminc/terraform-ecs//modules/ecs_instances"

  environment             = "${var.tags["Environment"]}"
  cluster                 = "${var.name}"
  instance_group          = "${var.name}"
  private_subnet_ids      = ["${var.subnets}"]
  aws_ami                 = "${data.aws_ami.ecs_ami.id}"
  instance_type           = "${var.instance_type}"
  max_size                = "${var.max_size}"
  min_size                = "${var.min_size}"
  desired_capacity        = "${var.desired_capacity}"
  vpc_id                  = "${var.vpc_id}"
  iam_instance_profile_id = "${aws_iam_instance_profile.this_instance_profile.id}"
  key_name                = "${var.key_name}"
  load_balancers          = ["${aws_elb.this_elb.name}"]
  depends_id              = "${var.vpc_id}"
  custom_userdata         = "${var.custom_userdata}"
  cloudwatch_prefix       = "${var.name}"
}
