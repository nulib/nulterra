variable "AWS_REGION"          {
  type = "string"
  default = "us-east-1"
}

resource "aws_instance" "example" {
  ami = "${lookup(var.AMIS, var.AWS_REGION)}"
  instance_type = "t2.micro"
  }

variable "stack_name"          		{ type = "string"}
variable "project_name"        		{ type = "string" }
variable "hosted_zone_name"    		{ type = "string" }
variable "ec2_keyname"         		{ type = "string" }
variable "ec2_private_keyfile" 		{ type = "string" }
variable "tags"                		{ type = "map"    }
variable "AWS_ACCESS_KEY_ID"   		{ type = "string" }
variable "AWS_SECRET_ACCESS_KEY"	{ type = "string" }

variable "AMIS" {
  type = 'map'
  default = {
    us-east-1 = "ami-1853ac65"
    us-east-2 = "ami-25615740"
    us-west-2 = "ami-d874e0a0"
  }
}
