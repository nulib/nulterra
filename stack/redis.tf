resource "aws_security_group" "redis" {
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group_rule" "redis_egress" {
  security_group_id = aws_security_group.redis.id
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_elasticache_subnet_group" "redis" {
  name = "${local.namespace}-redis"
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibility in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  subnet_ids = [module.vpc.private_subnets]
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${local.namespace}-redis"
  engine               = "redis"
  node_type            = "cache.t2.small"
  num_cache_nodes      = 1
  engine_version       = "5.0.3"
  parameter_group_name = "default.redis5.0"
  security_group_ids   = [aws_security_group.redis.id]
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.namespace}-redis"
    },
  )
}

resource "aws_route53_record" "redis" {
  zone_id = module.dns.private_zone_id
  name    = "redis.${local.private_zone_name}"
  type    = "CNAME"
  ttl     = 900
  records = [aws_elasticache_cluster.redis.cache_nodes[0].address]
}

