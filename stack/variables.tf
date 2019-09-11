variable "api_token_secret" {
  type = "string"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "azs" {
  type    = "list"
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "bastion_instance_type" {
  default = "t2.small"
}

variable "db_master_username" {
  default = "dbadmin"
}

variable "ec2_keyname" {
  type = "string"
}

variable "ec2_private_keyfile" {
  type = "string"
}

variable "enable_alarms" {
  default = true
}

variable "enable_iiif_cloudfront" {
  default = false
}

variable "environment" {
  type = "string"
}

variable "fcrepo_image" {
  default = "nulib/fcrepo4:4.7.5-s3fix"
}

variable "frontend_dns_names" {
  type    = "list"
  default = []
}

variable "hosted_zone_name" {
  type = "string"
}

variable "iiif_ssl_certificate_arn" {
  default = ""
}

variable "passthru_security_groups" {
  type    = "map"
  default = {}
}

variable "postgres_version" {
  default = "9.6.11"
}

variable "solr_capacity" {
  default = 3
}

variable "stack_name" {
  default = "stack"
}

variable "pager_alert" {
  type = "list"
}

variable "tags" {
  type    = "map"
  default = {}
}

variable "vpc_cidr_block" {
  default = "10.1.0.0/16"
}

variable "vpc_public_subnets" {
  type    = "list"
  default = ["10.1.2.0/24", "10.1.4.0/24", "10.1.6.0/24"]
}

variable "vpc_private_subnets" {
  type    = "list"
  default = ["10.1.1.0/24", "10.1.3.0/24", "10.1.5.0/24"]
}

variable "ip_whitelist" {
  type    = "string"
  default = "false"
}

variable "ua_blacklist" {
  type    = "string"
  default = "false"
}

variable "url_blacklist" {
  type    = "string"
  default = "false"
}

locals {
  namespace         = "${var.stack_name}-${var.environment}"
  public_zone_name  = "${var.stack_name}.${var.hosted_zone_name}"
  private_zone_name = "${var.stack_name}.vpc.${var.hosted_zone_name}"

  common_tags = "${merge(
    var.tags,
    map(
      "Terraform", "true",
      "Environment", "${local.namespace}",
      "Project", "Infrastructure"
    )
  )}"
}
