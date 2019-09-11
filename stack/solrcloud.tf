resource "aws_elastic_beanstalk_application" "solrcloud" {
  name = "${local.namespace}-solrcloud"
#  tags = "${merge(local.common_tags, map("Name", "${local.namespace}-solrcloud"))}" 
}
