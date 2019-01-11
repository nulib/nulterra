data "aws_iam_policy_document" "cloudwatch_metrics_lambda_access" {
  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricData",
      "cloudwatch:PutMetricData"
    ]
    resources = ["*"]
  }
}

resource "aws_lambda_permission" "solr_metrics_invoke_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${module.solr_metrics_function.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.solr_metrics_event.arn}"
}


module "solr_metrics_function" {
  source = "git://github.com/claranet/terraform-aws-lambda"

  function_name = "${local.namespace}-solr-metrics"
  description   = "Posts solr metrics to CloudWatch"
  handler       = "index.handler"
  runtime       = "nodejs8.10"
  timeout       = 300

  attach_policy = true
  policy        = "${data.aws_iam_policy_document.cloudwatch_metrics_lambda_access.json}"
  
  source_path = "${path.module}/lambdas/solr-metrics"

  attach_vpc_config = true
  vpc_config {
    subnet_ids         = ["${module.vpc.private_subnets}"]
    security_group_ids = ["${module.vpc.default_security_group_id}"]
  }

  environment {
    variables {
      SolrUrl = "http://${aws_route53_record.solr.name}/solr"
    }
  }
}

resource "aws_cloudwatch_event_rule" "solr_metrics_event" {
  name                  = "${local.namespace}-solr-metrics"
  description           = "Report solr metrics every 5 minutes"
  schedule_expression   = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "solr_metrics_lambda" {
  rule = "${aws_cloudwatch_event_rule.solr_metrics_event.name}"
  arn  = "${module.solr_metrics_function.function_arn}"
}

resource "aws_lambda_permission" "aggregate_metrics_invoke_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${module.aggregate_metrics_function.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.aggregate_metrics_event.arn}"
}

module "aggregate_metrics_function" {
  source = "git://github.com/claranet/terraform-aws-lambda"

  function_name = "${local.namespace}-aggregate-metrics"
  description   = "Aggregates instance Docker/Disk/Memory metrics and posts them to CloudWatch"
  handler       = "main.LambdaHandler.process"
  runtime       = "ruby2.5"
  timeout       = 300

  attach_policy = true
  policy        = "${data.aws_iam_policy_document.cloudwatch_metrics_lambda_access.json}"
  
  source_path = "${path.module}/lambdas/aggregate-metrics"
}

resource "aws_cloudwatch_event_rule" "aggregate_metrics_event" {
  name                  = "${local.namespace}-aggregate-metrics"
  description           = "Report aggregate metrics every minute"
  schedule_expression   = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "aggregate_metrics_lambda" {
  rule = "${aws_cloudwatch_event_rule.aggregate_metrics_event.name}"
  arn  = "${module.aggregate_metrics_function.function_arn}"
}

