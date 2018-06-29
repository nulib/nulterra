variable "aws_region" {
  type    = "string"
  default = "us-east-1"
}

variable "public_hostname" {
  type    = "string"
  default = ""
}

variable "streaming_hostname" {
  type    = "string"
  default = ""
}

variable "email" {
  type = "map"
}

variable "initial_user" {
  type    = "string"
  default = "archivist1@example.edu"
}

variable "trusted_signers" {
  type    = "list"
  default = []
}

variable "lti_key" {
  type = "string"
}

variable "lti_secret" {
  type = "string"
}
