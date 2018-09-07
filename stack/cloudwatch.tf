# resource "aws_cloudwatch_metric_alarm" "fcrepo-elasticbeanstalk-environmenthealth" {
#   alarm_name                = "xyzzy-s-fcrepo-elastic-beanstalk"
#   comparison_operator       = "GreaterThanOrEqualToThreshold"
#   evaluation_periods        = "2"
#   metric_name               = "EnvironmentHealth"
#   namespace                 = "AWS/ElasticBeanstalk"
#   period                    = "300"
#   statistic                 = "Average"
#   threshold                 = "25"
#   alarm_description         = "FCrepo Elastic Beanstalk Environment Health"
#   alarm_actions             = [
#                                 "arn:aws:sns:us-east-1:845225713889:OpsGenie",
#                               ]
#   insufficient_data_actions = []
# }
