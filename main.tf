terraform {
  backend "s3" {}
}

provider "aws" {
  region = "${var.aws_region}"
}

module "stack" {
  source                 = "./modules/stack"

  enable_iiif_cloudfront = true
  stack_name             = "${var.stack_name}"
  environment            = "${var.environment}"
  hosted_zone_name       = "${var.hosted_zone_name}"
  ec2_keyname            = "${var.ec2_keyname}"
  ec2_private_keyfile    = "${var.ec2_private_keyfile}"
  tags                   = "${var.tags}"
}

output "iiif_endpoint" {
  value = "${module.stack.iiif_endpoint}"
}

