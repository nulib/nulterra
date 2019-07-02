resource "aws_security_group" "minter" {
  name   = "${local.namespace}-minter-lambda"
  vpc_id = "${module.vpc.vpc_id}"
}

resource "aws_security_group_rule" "minter_outbound_access" {
  security_group_id = "${aws_security_group.minter.id}"
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "minter_redis_access" {
  security_group_id        = "${aws_security_group.redis.id}"
  type                     = "ingress"
  from_port                = "${aws_elasticache_cluster.redis.cache_nodes.0.port}"
  to_port                  = "${aws_elasticache_cluster.redis.cache_nodes.0.port}"
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.minter.id}"
}

module "this_noid_minter" {
  source = "git://github.com/nulib/terraform-aws-lambda"

  function_name = "${local.namespace}-noid-minter"
  description   = "NOID Minter"
  handler       = "main.handler"
  runtime       = "ruby2.5"
  timeout       = 10

  attach_policy = false

  source_path                    = "${path.module}/lambdas/noid-minter"
  reserved_concurrent_executions = "-1"

  attach_vpc_config = true

  vpc_config {
    subnet_ids         = ["${module.vpc.private_subnets}"]
    security_group_ids = ["${aws_security_group.minter.id}"]
  }

  environment {
    variables {
      REDIS_URL     = "redis://${aws_route53_record.redis.name}:${aws_elasticache_cluster.redis.cache_nodes.0.port}/"
      NOID_TEMPLATE = ".reeddeeedddk"
      STATE_KEY     = "${local.namespace}:noid:state"
    }
  }
}
