resource "aws_elastic_beanstalk_application" "solrcloud" {
  name = "${local.namespace}-solrcloud"
}
