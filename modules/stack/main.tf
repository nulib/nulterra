data "aws_elastic_beanstalk_solution_stack" "multi_docker" {
  most_recent   = true
  name_regex    = "^64bit Amazon Linux (.*) Multi-container Docker (.*)$"
}

resource "aws_s3_bucket" "app_sources" {
  bucket = "${var.stack_name}-${var.environment}-sources"
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    prefix = "/"
    enabled = true

    noncurrent_version_expiration {
      days = 30
    }
  }

  tags   = "${local.common_tags}"
}
