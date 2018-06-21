variable "email" {
  type = "map"
}
variable "initial_user" {
  type    = "string" 
  default = "archivist1@example.edu"
}
variable "trusted_signers" {
  type = "list"
  default = []
}
variable "derivatives_bucket" {
  type = "string"
}
