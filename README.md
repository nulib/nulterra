# Terraforming NUL

## Initialization

1. Download and install [Terraform](https://www.terraform.io/downloads.html)
1. Clone this repo
1. `cd <working_dir>/stack`
1. Create an S3 bucket to hold the terraform state.
1. Create a `terraform.tfvars` file with the specifics of the stack you want to create:
    ```
    stack_name          = "my_repo_stack"
    environment         = "staging"
    hosted_zone_name    = "rdc-staging.library.northwestern.edu"
    ec2_keyname         = "my_keypair"
    ec2_private_keyfile = "/path/to/private/key/for/my_keypair"
    tags {
      Creator    = "me"
      AnotherTag = "Whatever value I want!"
    }
    ```
  * Note: You can have more than one variable file and pass the name on the command line to manage more than one stack.
1. Execute `terraform init`.
  * You will be prompted for an S3 bucket, key, and region in which to store the state. This is useful when
    executing terraform on multiple machines (or working as a team) because it allows state to remain in sync.
  * If the state file already exists in S3, you _may_ be prompted to create a local copy.

## Bringing up the stack

To see the changes Terraform will make:

    terraform plan

To actually make those changes:

    terraform apply

You can proceed with `terraform plan` and `terraform apply` as often as you want to see and apply changes to the
stack. Changes you make to the `*.tf` files  will automatically be reflected in the resources under Terraform's
control.
