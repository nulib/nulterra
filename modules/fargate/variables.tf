variable "container_definitions" {
  type = string
}

variable "container_name" {
  type    = string
  default = "app"
}

variable "desired_count" {
  type    = string
  default = "1"
}

variable "namespace" {
  type = string
}

variable "family" {
  type = string
}

variable "cpu" {
  type    = string
  default = "1024"
}

variable "memory" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "vpc_id" {
  type = string
}

variable "instance_port" {
  type    = string
  default = "80"
}

variable "internal" {
  type    = string
  default = "true"
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "load_balanced" {
  type    = string
  default = "true"
}

variable "security_groups" {
  type    = list(string)
  default = []
}

locals {
  family_title = "${upper(substr(var.family, 1, 1))}${lower(substr(var.family, 2, -1))}"
}

