variable "aws_region" {
  type    = "string"
  default = "us-east-1"
}

variable "stack_name" {
  type    = "string"
  default = "stack"
}

data "aws_ssm_parameter" "db_master_username" {
  name = "/terraform/${var.stack_name}/db_master_username"
}
data "aws_ssm_parameter" "environment" {
  name = "/terraform/${var.stack_name}/environment"
}
data "aws_ssm_parameter" "vpc_cidr_block" {
  name = "/terraform/${var.stack_name}/vpc_cidr_block"
}
data "aws_ssm_parameter" "subnet_config_public_subnets" {
  name = "/terraform/${var.stack_name}/subnet_config_public_subnets"
}
data "aws_ssm_parameter" "subnet_config_private_subnets" {
  name = "/terraform/${var.stack_name}/subnet_config_private_subnets"
}
data "aws_ssm_parameter" "azs" {
  name = "/terraform/${var.stack_name}/azs"
}
data "aws_ssm_parameter" "bastion_instance_type" {
  name = "/terraform/${var.stack_name}/bastion_instance_type"
}
data "aws_ssm_parameter" "hosted_zone_name" {
  name = "/terraform/${var.stack_name}/hosted_zone_name"
}
data "aws_ssm_parameter" "ec2_keyname" {
  name = "/terraform/${var.stack_name}/ec2_keyname"
}
data "aws_ssm_parameter" "ec2_private_keyfile" {
  name = "/terraform/${var.stack_name}/ec2_private_keyfile"
}
data "aws_ssm_parameter" "enable_iiif_cloudfront" {
  name = "/terraform/${var.stack_name}/enable_iiif_cloudfront"
}
data "aws_ssm_parameter" "tag_names" {
  name = "/terraform/${var.stack_name}/tag_names"
}
data "aws_ssm_parameter" "tag_values" {
  name = "/terraform/${var.stack_name}/tag_values"
}
data "external" "environment" {
  program = ["${path.module}/support/json_environ.sh"]
  query   = {}
}

locals {
  environment            = "${data.aws_ssm_parameter.environment.value}"
  vpc_cidr_block         = "${data.aws_ssm_parameter.vpc_cidr_block.value}"
  azs                    = "${split(",", data.aws_ssm_parameter.azs.value)}"
  bastion_instance_type  = "${data.aws_ssm_parameter.bastion_instance_type.value}"
  db_master_username     = "${data.aws_ssm_parameter.db_master_username.value}"
  hosted_zone_name       = "${data.aws_ssm_parameter.hosted_zone_name.value}"
  ec2_keyname            = "${data.aws_ssm_parameter.ec2_keyname.value}"
  ec2_private_keyfile    = "${replace(data.aws_ssm_parameter.ec2_private_keyfile.value, "~/", "${data.external.environment.result.HOME}/")}"
  enable_iiif_cloudfront = "${data.aws_ssm_parameter.enable_iiif_cloudfront.value}"
  tags                   = "${zipmap(split(",", data.aws_ssm_parameter.tag_names.value), split(",", data.aws_ssm_parameter.tag_values.value))}"

  subnet_config = {
    public_subnets  = "${split(",", data.aws_ssm_parameter.subnet_config_public_subnets.value)}"
    private_subnets = "${split(",", data.aws_ssm_parameter.subnet_config_private_subnets.value)}"
  }
}

locals {
  namespace         = "${var.stack_name}-${local.environment}"
  public_zone_name  = "${var.stack_name}.${local.hosted_zone_name}"
  private_zone_name = "${var.stack_name}.vpc.${local.hosted_zone_name}"

  common_tags = "${merge(
    local.tags,
    map(
      "Terraform", "true",
      "Environment", "${local.namespace}",
      "Project", "Infrastructure"
    )
  )}"
}
