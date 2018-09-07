resource "aws_cloudwatch_metric_alarm" "fcrepo-poor" {
  alarm_name                = "${var.stack_name}-${var.environment}-fcrepo-poor"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "6"
  metric_name               = "EnvironmentHealth"
  namespace                 = "AWS/ElasticBeanstalk"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "20"
  alarm_description         = "FCrepo Elastic Beanstalk Environment Health Poor"
  dimensions  {
      "EnvironmentName" = "${var.stack_name}-${var.environment}-fcrepo"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "fcrepo" {
  alarm_name                = "${var.stack_name}-${var.environment}-fcrepo"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "EnvironmentHealth"
  namespace                 = "AWS/ElasticBeanstalk"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "25"
  alarm_description         = "FCrepo Elastic Beanstalk Environment Health"
  dimensions  {
      "EnvironmentName" = "${var.stack_name}-${var.environment}-fcrepo"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "solr-poor" {
  alarm_name                = "${var.stack_name}-${var.environment}-solr-poor"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "6"
  metric_name               = "EnvironmentHealth"
  namespace                 = "AWS/ElasticBeanstalk"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "20"
  alarm_description         = "Solr Elastic Beanstalk Environment Health Poor"
  dimensions {
      "EnvironmentName" = "${var.stack_name}-${var.environment}-solr"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "solr" {
  alarm_name                = "${var.stack_name}-${var.environment}-solr"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "EnvironmentHealth"
  namespace                 = "AWS/ElasticBeanstalk"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "25"
  alarm_description         = "Solr Elastic Beanstalk Environment Health"
  dimensions {
      "EnvironmentName" = "${var.stack_name}-${var.environment}-solr"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "zookeeper-poor" {
  alarm_name                = "${var.stack_name}-${var.environment}-zookeeper-poor"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "6"
  metric_name               = "EnvironmentHealth"
  namespace                 = "AWS/ElasticBeanstalk"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "20"
  alarm_description         = "Zookeeper Elastic Beanstalk Environment Health Poor"
  dimensions {
      "EnvironmentName" = "${var.stack_name}-${var.environment}-zookeeper"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "zookeeper" {
  alarm_name                = "${var.stack_name}-${var.environment}-zookeeper"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "EnvironmentHealth"
  namespace                 = "AWS/ElasticBeanstalk"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "25"
  alarm_description         = "Zookeeper Elastic Beanstalk Environment Health"
  dimensions {
      "EnvironmentName" = "${var.stack_name}-${var.environment}-zookeeper"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "donut-batch-worker-poor" {
  alarm_name                = "${var.stack_name}-${var.environment}-donut-batch-worker-poor"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "6"
  metric_name               = "EnvironmentHealth"
  namespace                 = "AWS/ElasticBeanstalk"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "20"
  alarm_description         = "Donut Batch Worker Elastic Beanstalk Environment Health Poor"
  dimensions {
      "EnvironmentName" = "${var.stack_name}-${var.environment}-donut-batch-worker"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "donut-batch-worker" {
  alarm_name                = "${var.stack_name}-${var.environment}-donut-batch-worker"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "EnvironmentHealth"
  namespace                 = "AWS/ElasticBeanstalk"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "25"
  alarm_description         = "Donut Batch Worker Elastic Beanstalk Environment Health"
  dimensions {
      "EnvironmentName" = "${var.stack_name}-${var.environment}-donut-batch-worker"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "donut-webapp-poor" {
  alarm_name                = "${var.stack_name}-${var.environment}-donut-webapp-poor"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "6"
  metric_name               = "EnvironmentHealth"
  namespace                 = "AWS/ElasticBeanstalk"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "20"
  alarm_description         = "Donut Webapp Elastic Beanstalk Environment Health Poor"
  dimensions {
      "EnvironmentName" = "${var.stack_name}-${var.environment}-donut-webapp"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "donut-webapp" {
  alarm_name                = "${var.stack_name}-${var.environment}-donut-webapp"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "EnvironmentHealth"
  namespace                 = "AWS/ElasticBeanstalk"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "25"
  alarm_description         = "Donut Webapp Elastic Beanstalk Environment Health"
  dimensions {
      "EnvironmentName" = "${var.stack_name}-${var.environment}-donut-webapp"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "avr-webapp-poor" {
  alarm_name                = "${var.stack_name}-${var.environment}-avr-webapp-poor"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "6"
  metric_name               = "EnvironmentHealth"
  namespace                 = "AWS/ElasticBeanstalk"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "20"
  alarm_description         = "AVR Webapp Elastic Beanstalk Environment Health Poor"
  dimensions {
      "EnvironmentName" = "${var.stack_name}-${var.environment}-avr-webapp"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "avr-webapp" {
  alarm_name                = "${var.stack_name}-${var.environment}-avr-webapp"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "EnvironmentHealth"
  namespace                 = "AWS/ElasticBeanstalk"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "25"
  alarm_description         = "AVR Webapp Elastic Beanstalk Environment Health"
  dimensions {
      "EnvironmentName" = "${var.stack_name}-${var.environment}-avr-webapp"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "avr-batch-worker-poor" {
  alarm_name                = "${var.stack_name}-${var.environment}-avr-batch-worker-poor"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "6"
  metric_name               = "EnvironmentHealth"
  namespace                 = "AWS/ElasticBeanstalk"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "20"
  alarm_description         = "AVR Batch Worker Elastic Beanstalk Environment Health Poor"
  dimensions {
      "EnvironmentName" = "${var.stack_name}-${var.environment}-avr-batch-worker"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "avr-batch-worker" {
  alarm_name                = "${var.stack_name}-${var.environment}-avr-batch-worker"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "EnvironmentHealth"
  namespace                 = "AWS/ElasticBeanstalk"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "25"
  alarm_description         = "AVR Batch Worker Elastic Beanstalk Environment Health"
  dimensions {
      "EnvironmentName" = "${var.stack_name}-${var.environment}-avr-batch-worker"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "avr-ui-worker-poor" {
  alarm_name                = "${var.stack_name}-${var.environment}-avr-ui-worker-poor"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "6"
  metric_name               = "EnvironmentHealth"
  namespace                 = "AWS/ElasticBeanstalk"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "20"
  alarm_description         = "AVR UI Worker Elastic Beanstalk Environment Health Poor"
  dimensions {
      "EnvironmentName" = "${var.stack_name}-${var.environment}-avr-ui-worker"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "avr-ui-worker" {
  alarm_name                = "${var.stack_name}-${var.environment}-avr-ui-worker"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "EnvironmentHealth"
  namespace                 = "AWS/ElasticBeanstalk"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "25"
  alarm_description         = "AVR UI Worker Elastic Beanstalk Environment Health"
  dimensions {
      "EnvironmentName" = "${var.stack_name}-${var.environment}-avr-ui-worker"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "arch-poor" {
  alarm_name                = "${var.stack_name}-${var.environment}-arch-poor"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "6"
  metric_name               = "EnvironmentHealth"
  namespace                 = "AWS/ElasticBeanstalk"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "20"
  alarm_description         = "Arch Worker Elastic Beanstalk Environment Health Poor"
  dimensions {
      "EnvironmentName" = "${var.stack_name}-${var.environment}-arch"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "arch" {
  alarm_name                = "${var.stack_name}-${var.environment}-arch"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "EnvironmentHealth"
  namespace                 = "AWS/ElasticBeanstalk"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "25"
  alarm_description         = "Arch Worker Elastic Beanstalk Environment Health"
  dimensions {
      "EnvironmentName" = "${var.stack_name}-${var.environment}-arch"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "arch-ui-worker-poor" {
  alarm_name                = "${var.stack_name}-${var.environment}-arch-ui-worker-poor"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "6"
  metric_name               = "EnvironmentHealth"
  namespace                 = "AWS/ElasticBeanstalk"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "20"
  alarm_description         = "Arch UI Worker Elastic Beanstalk Environment Health Poor"
  dimensions {
      "EnvironmentName" = "${var.stack_name}-${var.environment}-arch-ui-worker"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "arch-ui-worker" {
  alarm_name                = "${var.stack_name}-${var.environment}-arch-ui-worker"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "EnvironmentHealth"
  namespace                 = "AWS/ElasticBeanstalk"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "25"
  alarm_description         = "Arch UI Worker Elastic Beanstalk Environment Health"
  dimensions {
      "EnvironmentName" = "${var.stack_name}-${var.environment}-arch-ui-worker"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "cantaloupe-ecs-high-cpu-utilization" {
  alarm_name                = "${var.stack_name}-${var.environment}-cantaloupe-ecs-high-cpu-utilization"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "5"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/ECS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "85"
  alarm_description         = "Cantaloupe ECS High CPU Utilization"
  dimensions {
      "ClusterName" = "${var.stack_name}-${var.environment}-cantaloupe"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "cantaloupe-ecs-high-memory-utilization" {
  alarm_name                = "${var.stack_name}-${var.environment}-cantaloupe-ecs-high-memory-utilization"
  metric_name               = "MemoryUtilization"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = "10"
  evaluation_periods        = "2"
  namespace                 = "AWS/ECS"
  period                    = "300"
  statistic                 = "Average"
  alarm_description         = "Cantaloupe ECS High Memory Utilization"
  dimensions {
      "ClusterName" = "${var.stack_name}-${var.environment}-cantaloupe"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "avr-elasticache-swapusage" {
  alarm_name                = "${var.stack_name}-${var.environment}-avr-elasticache-swapusage"
  metric_name               = "SwapUsage"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = "5000000"
  evaluation_periods        = "4"
  namespace                 = "AWS/ElastiCache"
  period                    = "300"
  statistic                 = "Average"
  alarm_description         = "AVR ElastiCache High Swap UsageUtilization"
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "avr-elasticache-freeablememory" {
  alarm_name                = "${var.stack_name}-${var.environment}-avr-elasticache-freeablememory"
  metric_name               = "FreeableMemory"
  comparison_operator       = "LessThanThreshold"
  threshold                 = "1000000000"
  evaluation_periods        = "2"
  namespace                 = "AWS/ElastiCache"
  period                    = "300"
  statistic                 = "Average"
  alarm_description         = "AVR ElastiCache Low Freeable Momory"
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
resource "aws_cloudwatch_metric_alarm" "rds-low-free-storage-space" {
  alarm_name                = "${var.stack_name}-${var.environment}-rds-low-free-storage-space"
  metric_name               = "FreeStorageSpace"
  comparison_operator       = "LessThanOrEqualToThreshold"
  threshold                 = "2500000000"
  evaluation_periods        = "2"
  namespace                 = "AWS/RDS"
  period                    = "300"
  statistic                 = "Average"
  alarm_description         = "RDS Table Space Alarm"
  dimensions {
      "DBInstanceIdentifier" = "${var.stack_name}-${var.environment}-db"
  }
  alarm_actions             = [ "${var.pager_alert}", ]
  insufficient_data_actions = []
}
# 20181004 JRB This doesn't work because I need to know the ARN of the ELB and I'm 
# Not sure how to do that.
#
# resource "aws_cloudwatch_metric_alarm" "fcrepo-unhealthy-host-count" {
#   alarm_name                = "${var.stack_name}-${var.environment}-fcrepo-unhealthy-host-count"
#   metric_name               = "UnHealthyHostCount"
#   comparison_operator       = "GreaterThanOrEqualToThreshold"
#   threshold                 = "1"
#   evaluation_periods        = "1"
#   namespace                 = "AWS/Application/ELB"
#   period                    = "300"
#   statistic                 = "Average"
#   alarm_description         = "Fedora ELB UnHealthy Host Count"
#   alarm_actions             = [ "${var.pager_alert}", ]
#   insufficient_data_actions = []
# }
### cantaloupe elasticsearch frontend postgres redis solrcloud vpc
