resource "aws_cloudwatch_event_rule" "batch_status_finished" {
  name                  = "${local.namespace}-batch-status-finished"
  description           = "Check on finished batch jobs"
  schedule_expression   = "rate(15 minutes)"
}

resource "aws_cloudwatch_event_target" "batch_status_finished" {
  rule  = "${aws_cloudwatch_event_rule.batch_status_finished.name}"
  arn   = "${module.batch_status_finished.function_arn}"
}

resource "aws_lambda_permission" "batch_status_finished" {
  statement_id    = "AllowExecutionFromCloudWatch"
  action          = "lambda:InvokeFunction"
  function_name   = "${module.batch_status_finished.function_name}"
  principal       = "events.amazonaws.com"
}

module "batch_status_finished" {
  source = "git://github.com/nulib/terraform-aws-lambda"

  function_name = "${local.namespace}-batch-finished"
  description   = "Run batch status checks"
  handler       = "index.handler"
  runtime       = "nodejs8.10"
  timeout       = 300

  source_path   = "${path.module}/lambdas/batch_status"

  attach_policy = true
  policy        = "${data.aws_iam_policy_document.this_batch_ingest_access.json}"

  environment {
    variables {
      JobClassName = "IngestBatchStatusEmailJobs::IngestFinished"
      QueueUrl     = "${aws_sqs_queue.this_batch_queue.id}"
      Secret       = "${random_id.secret_key_base.hex}"
    }
  }
}

resource "aws_cloudwatch_event_rule" "batch_status_stalled" {
  name                  = "${local.namespace}-batch-status-stalled"
  description           = "Check on stalled batch jobs"
  schedule_expression   = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "batch_status_stalled" {
  rule  = "${aws_cloudwatch_event_rule.batch_status_stalled.name}"
  arn   = "${module.batch_status_stalled.function_arn}"
}

resource "aws_lambda_permission" "batch_status_stalled" {
  statement_id    = "AllowExecutionFromCloudWatch"
  action          = "lambda:InvokeFunction"
  function_name   = "${module.batch_status_stalled.function_name}"
  principal       = "events.amazonaws.com"
}

module "batch_status_stalled" {
  source = "git://github.com/nulib/terraform-aws-lambda"

  function_name = "${local.namespace}-batch-stalled"
  description   = "Run batch stalled checks"
  handler       = "index.handler"
  runtime       = "nodejs8.10"
  timeout       = 300

  source_path   = "${path.module}/lambdas/batch_status"

  attach_policy = true
  policy        = "${data.aws_iam_policy_document.this_batch_ingest_access.json}"

  environment {
    variables {
      JobClassName = "IngestBatchStatusEmailJobs::StalledJob"
      QueueUrl     = "${aws_sqs_queue.this_batch_queue.id}"
      Secret       = "${random_id.secret_key_base.hex}"
    }
  }
}
