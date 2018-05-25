data "aws_iam_policy_document" "ecs_logging" {
  statement {
    sid = ""
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect = "Allow"
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    sid = ""
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "task_role" {
  name               = "${var.namespace}-${var.family}-task-role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_assume_role.json}"
}

resource "aws_iam_policy" "execution_policy" {
  name               = "${var.namespace}-${var.family}-exec-policy"
  policy             = "${data.aws_iam_policy_document.ecs_logging.json}"
}

resource "aws_iam_role" "execution_role" {
  name               = "${var.namespace}-${var.family}-exec-role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "service_role_policy" {
  role       = "${aws_iam_role.execution_role.name}"
  policy_arn = "${aws_iam_policy.execution_policy.arn}"
}

resource "aws_ecs_task_definition" "this_task" {
  family                   = "${var.namespace}-${var.family}"
  container_definitions    = "${var.container_definitions}"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "${var.cpu}"
  network_mode             = "awsvpc"
  memory                   = "${var.memory}"
  execution_role_arn       = "${aws_iam_role.execution_role.arn}"
  task_role_arn            = "${aws_iam_role.task_role.arn}"
}

resource "aws_security_group" "this_lb_security_group" {
  name        = "${var.namespace}-${var.family}-lb"
  description = "${local.family_title} Load Balancer Security Group"
  vpc_id      = "${var.vpc_id}"
  tags        = "${var.tags}"

  egress {
    from_port       = "${var.instance_port}"
    to_port         = "${var.instance_port}"
    protocol        = "tcp"
    security_groups = ["${aws_security_group.this_instance_security_group.id}"]
  }
}

resource "aws_security_group" "this_instance_security_group" {
  name        = "${var.namespace}-${var.family}-i"
  description = "${local.family_title} Load Balancer Security Group"
  vpc_id      = "${var.vpc_id}"
  tags        = "${var.tags}"
}

resource "aws_security_group_rule" "this_instance_ingress" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.this_instance_security_group.id}"
  from_port                = "${var.instance_port}"
  to_port                  = "${var.instance_port}"
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.this_lb_security_group.id}"
}

resource "aws_ecs_cluster" "this_cluster" {
  name = "${var.namespace}-${var.family}"
}

resource "aws_lb" "this_load_balancer" {
  count            = "${var.load_balanced == "true" ? 1 : 0}"
  name             = "${var.namespace}-${var.family}-lb"
  internal         = "${var.internal == "true" ? true : false}"
  security_groups  = ["${aws_security_group.this_lb_security_group.id}"]
  subnets          = ["${split(",", var.internal == "true" ? join(",", var.private_subnets) : join(",", var.public_subnets))}"]

  tags = "${var.tags}"
}

resource "aws_lb_target_group" "this_target_group" {
  count       = "${var.load_balanced == "true" ? 1 : 0}"
  name        = "${var.namespace}-${var.family}"
  target_type = "ip"
  port        = "${var.instance_port}"
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_lb_listener" "this_listener" {
  count             = "${var.load_balanced == "true" ? 1 : 0}"
  load_balancer_arn = "${aws_lb.this_load_balancer.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.this_target_group.arn}"
    type             = "forward"
  }
}

resource "aws_ecs_service" "this_service" {
  count           = "${var.load_balanced == "true" ? 0 : 1}"
  depends_on      = ["aws_lb_listener.this_listener"]
  name            = "${var.namespace}-${var.family}"
  cluster         = "${aws_ecs_cluster.this_cluster.id}"
  task_definition = "${aws_ecs_task_definition.this_task.arn}"
  desired_count   = "${var.desired_count}"
  launch_type     = "FARGATE"

  network_configuration {
    subnets = ["${var.private_subnets}"]
    security_groups = ["${concat(var.security_groups, aws_security_group.this_instance_security_group.*.id)}"]
    assign_public_ip = false
  }
}

resource "aws_ecs_service" "this_lb_service" {
  count           = "${var.load_balanced == "true" ? 1 : 0}"
  depends_on      = ["aws_lb_listener.this_listener"]
  name            = "${var.namespace}-${var.family}"
  cluster         = "${aws_ecs_cluster.this_cluster.id}"
  task_definition = "${aws_ecs_task_definition.this_task.arn}"
  desired_count   = "${var.desired_count}"
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.this_target_group.arn}"
    container_name   = "${var.container_name}"
    container_port   = "${var.instance_port}"
  }

  network_configuration {
    subnets = ["${var.private_subnets}"]
    security_groups = ["${concat(var.security_groups, aws_security_group.this_instance_security_group.*.id)}"]
    assign_public_ip = false
  }
}
