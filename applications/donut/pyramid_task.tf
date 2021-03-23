data "aws_s3_bucket" "stack_fcrepo_binary_bucket" {
  bucket = "${local.namespace}-fedora-binaries"
}

data "aws_iam_role" "task_execution_role" {
  name = "ecsTaskExecutionRole"
}

resource "aws_sqs_queue" "this_pyramid_tiff_deadletter_queue" {
  name = "${local.namespace}-create-pyramid-tiffs-dead-letter-queue"
  tags = local.common_tags
}

resource "aws_sqs_queue" "this_pyramid_tiff_queue" {
  name                       = "${local.namespace}-create-pyramid-tiffs"
  delay_seconds              = 0
  visibility_timeout_seconds = 360
  redrive_policy             = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.this_pyramid_tiff_deadletter_queue.arn}\",\"maxReceiveCount\":5}"
  tags                       = local.common_tags
}

data "aws_iam_policy_document" "this_pyramid_tiff_access" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListAllMyBuckets",
      "sqs:ListQueues",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]

    resources = [
      data.aws_s3_bucket.stack_fcrepo_binary_bucket.arn,
      data.terraform_remote_state.stack.outputs.iiif_pyramid_bucket_arn,
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${data.aws_s3_bucket.stack_fcrepo_binary_bucket.arn}/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["${data.terraform_remote_state.stack.outputs.iiif_pyramid_bucket_arn}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage",
    ]

    resources = [aws_sqs_queue.this_pyramid_tiff_queue.arn]
  }
}

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "this_pyramid_tiff_policy" {
  name   = "${local.namespace}-create-pyramid"
  policy = data.aws_iam_policy_document.this_pyramid_tiff_access.json
}

resource "aws_iam_role" "this_pyramid_tiff_role" {
  name               = "${local.namespace}-create-pyramid-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

resource "aws_iam_role_policy_attachment" "this_pyramid_tiff_role_policy_attachment" {
  role       = aws_iam_role.this_pyramid_tiff_role.name
  policy_arn = aws_iam_policy.this_pyramid_tiff_policy.arn
}

data "template_file" "pyramid_container_definitions" {
  template = file("./templates/create_pyramid_tiff_container.json.tpl")

  vars = {
    image_name = "nulib/pyramid:latest"
    queue_url  = aws_sqs_queue.this_pyramid_tiff_queue.id
    region     = data.terraform_remote_state.stack.outputs.aws_region
    task_name  = "${local.namespace}-create-pyramid"
  }
}

resource "aws_ecs_task_definition" "this_pyramid_tiff_task" {
  family                   = "${local.namespace}-create-pyramid"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = data.aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.this_pyramid_tiff_role.arn
  cpu                      = "2048"
  memory                   = "8192"
  container_definitions    = data.template_file.pyramid_container_definitions.rendered
}

data "aws_iam_policy_document" "this_pyramid_trigger_access" {
  statement {
    effect    = "Allow"
    actions   = ["iam:Passrole"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["sqs:*"]
    resources = [aws_sqs_queue.this_pyramid_tiff_queue.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecs:ListTasks",
      "ecs:RunTask",
      "ec2:Describe*",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:List*",
      "s3:Get*",
    ]

    resources = [
      data.terraform_remote_state.stack.outputs.iiif_pyramid_bucket_arn,
      "${data.terraform_remote_state.stack.outputs.iiif_pyramid_bucket_arn}/*",
    ]
  }
}

resource "aws_cloudwatch_event_rule" "trigger_pyramid_rule" {
  name                = "${local.namespace}-check-pyramid-queue"
  description         = "Check pyramid tiff queue for unhandled messages"
  schedule_expression = "rate(3 minutes)"
}

resource "aws_cloudwatch_event_target" "trigger_pyramid_rule" {
  rule = aws_cloudwatch_event_rule.trigger_pyramid_rule.name
  arn  = module.this_pyramid_trigger.function_arn
}

resource "aws_lambda_permission" "trigger_pyramid_rule" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.this_pyramid_trigger.function_name
  principal     = "events.amazonaws.com"
}

module "this_pyramid_trigger" {
  source = "git://github.com/nulib/terraform-aws-lambda"

  function_name = "${local.namespace}-trigger-pyramid"
  description   = "Pyramid TIFF Creation trigger"
  handler       = "main.handle_event"
  runtime       = "ruby2.5"
  timeout       = 30

  attach_policy = true
  policy        = data.aws_iam_policy_document.this_pyramid_trigger_access.json

  source_path                    = "${path.module}/lambdas/pyramid_trigger"
  reserved_concurrent_executions = "-1"

  environment = {
    variables = {
      QueueUrl = aws_sqs_queue.this_pyramid_tiff_queue.id
      TaskArn  = aws_ecs_task_definition.this_pyramid_tiff_task.arn
      VpcId    = data.terraform_remote_state.stack.outputs.vpc_id
    }
  }
}

