data "aws_iam_policy_document" "instance_tagger_lambda_access" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:CreateTags",
    ]

    resources = ["*"]
  }
}

resource "aws_lambda_permission" "instance_tagger_invoke_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${module.instance_tagger_function.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.instance_tagger_event.arn}"
}

resource "aws_cloudwatch_event_target" "instance_tagger_lambda" {
  rule = "${aws_cloudwatch_event_rule.instance_tagger_event.name}"
  arn  = "${module.instance_tagger_function.function_arn}"
}

resource "aws_cloudwatch_event_rule" "instance_tagger_event" {
  event_pattern = <<__EOF__
{
  "detail-type": [ "EC2 Instance State-change Notification" ],
  "detail": {
    "state": [ "running" ]
  }
}
__EOF__
}

module "instance_tagger_function" {
  source = "git://github.com/nulib/terraform-aws-lambda"

  function_name = "${local.namespace}-instance-tagger"
  description   = "Tags newly booted instances with a puppet certname"
  handler       = "main.handle_event"
  runtime       = "ruby2.5"
  timeout       = 60

  attach_policy = true
  policy        = "${data.aws_iam_policy_document.instance_tagger_lambda_access.json}"

  source_path                    = "${path.module}/lambdas/instance-tagger"
  reserved_concurrent_executions = "-1"
}
