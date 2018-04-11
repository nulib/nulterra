locals {
  namespace_prefix = "${var.namespace}-${var.name}"
}

data "aws_iam_policy_document" "container_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["ecs.amazonaws.com", "ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_service_permissions_document" {
  statement {
    actions = [
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress"
    ]
    effect = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_service_permissions" {
  name   = "${var.namespace}-${var.name}-ecs-service-permissions"
  policy = "${data.aws_iam_policy_document.ecs_service_permissions_document.json}"
}
