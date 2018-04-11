variable "namespace"     { type = "string" }
variable "name"          { type = "string" }
variable "vpc_id"        { type = "string" }
variable "instance_port" { type = "string" }
variable "lb_port"       { type = "string" }
variable "subnets"       { type = "list"   }
variable "key_name"      { type = "string" }

variable "min_size" {
  type = "string"
  default = "1"
}

variable "desired_capacity" {
  type = "string"
  default = "1"
}

variable "max_size" {
  type = "string"
  default = "1"
}

variable "custom_userdata" {
  type = "string"
  default = ""
}

variable "instance_type" {
  type = "string"
  default = "t2.small"
}

variable "health_check_target" {
  type = "string"
  default = "HTTP:/"
}

variable "health_check_healthy_threshold" {
  type = "string"
  default = 2
}

variable "health_check_unhealthy_threshold" {
  type = "string"
  default = 2
}

variable "health_check_timeout" {
  type = "string"
  default = 3
}

variable "health_check_interval" {
  type = "string"
  default = 30
}


variable "container_definitions" {
  type = "string"
  default = ""
}

variable "instance_protocol" {
  type = "string"
  default = "http"
}

variable "lb_protocol" {
  type = "string"
  default = "http"
}

variable "client_access" {
  type = "list"
  default = []
}

variable "cidr_access" {
  type = "list"
  default = []
}

variable "create_task_definition" {
  type = "string"
  default = "true"
}

variable "existing_task_definition_arn" {
  type = "string"
  default = ""
}

variable "tags" {
  type = "map"
  default = {}
}
