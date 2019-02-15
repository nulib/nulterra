data "aws_iam_policy_document" "decommissioner_lambda_access" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter*",
      "ec2:DescribeInstances"
    ]
    resources = ["*"]
  }
}

resource "aws_lambda_permission" "decommissioner_invoke_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${module.decommissioner_function.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.decommissioner_event.arn}"
}

resource "aws_cloudwatch_event_target" "decommissioner_lambda" {
  rule = "${aws_cloudwatch_event_rule.decommissioner_event.name}"
  arn  = "${module.decommissioner_function.function_arn}"
}

resource "aws_cloudwatch_event_rule" "decommissioner_event" {
  event_pattern = <<__EOF__
{
  "detail-type": [ "EC2 Instance State-change Notification" ],
  "detail": {
    "state": [ "shutting-down" ]
  }
}
__EOF__
}

module "decommissioner_function" {
  source = "git://github.com/nulib/terraform-aws-lambda"

  function_name = "${local.namespace}-puppet-decommissioner"
  description   = "Decommissions nodes from puppet"
  handler       = "main.handle_event"
  runtime       = "ruby2.5"
  timeout       = 300

  attach_policy = true
  policy        = "${data.aws_iam_policy_document.decommissioner_lambda_access.json}"
  
  source_path = "${path.module}/lambdas/puppet-decommissioner"
}
