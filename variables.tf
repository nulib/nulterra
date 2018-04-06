variable "aws_region"          {
  type = "string"
  default = "us-east-1"
}

variable "stack_name"          { type = "string" }
variable "project_name"        { type = "string" }
variable "hosted_zone_name"    { type = "string" }
variable "ec2_keyname"         { type = "string" }
variable "ec2_private_keyfile" { type = "string" }
variable "tags"                { type = "map"    }
