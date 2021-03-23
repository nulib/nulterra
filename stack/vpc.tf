module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.66.0"

  name = "${local.namespace}-vpc"

  azs             = var.azs
  cidr            = var.vpc_cidr_block
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_dns_hostnames         = true
  enable_dns_support           = true
  enable_nat_gateway           = true
  single_nat_gateway           = true
  create_database_subnet_group = false

  enable_ec2_endpoint             = true
  enable_s3_endpoint              = true
  enable_ssm_endpoint             = true
  ec2_endpoint_security_group_ids = [module.vpc.default_security_group_id]
  ssm_endpoint_security_group_ids = [module.vpc.default_security_group_id]

  tags = local.common_tags
}

module "dns" {
  source  = "infrablocks/dns-zones/aws"
  version = "0.4.0"

  domain_name         = local.public_zone_name
  private_domain_name = local.private_zone_name

  # Default VPC
  private_zone_vpc_id     = module.vpc.vpc_id
  private_zone_vpc_region = var.aws_region
}

data "aws_route53_zone" "hosted_zone" {
  name = var.hosted_zone_name
}

resource "aws_route53_record" "public_zone" {
  zone_id = data.aws_route53_zone.hosted_zone.id
  type    = "NS"
  name    = local.public_zone_name
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibility in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  records = [module.dns.public_zone_name_servers]
  ttl     = 300
}

