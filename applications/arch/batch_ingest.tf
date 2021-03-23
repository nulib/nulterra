data "aws_iam_policy_document" "this_batch_ingest_access" {
  statement {
    effect    = "Allow"
    actions   = ["iam:Passrole"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["sqs:*"]
    resources = [aws_sqs_queue.this_ui_fifo_queue.arn]
  }
}

module "this_batch_ingest" {
  source = "git://github.com/nulib/terraform-aws-lambda"

  function_name = "${data.terraform_remote_state.stack.outputs.stack_name}-${local.app_name}-batch-ingest"
  description   = "Batch Ingest trigger for ${local.app_name}"
  handler       = "index.handler"
  runtime       = "nodejs10.x"
  timeout       = 300

  attach_policy = true
  policy        = data.aws_iam_policy_document.this_batch_ingest_access.json

  source_path                    = "${path.module}/lambdas/batch_ingest_notification"
  reserved_concurrent_executions = "-1"

  environment = {
    variables = {
      JobClassName = "ProquestIngestPackageJob"
      Secret       = random_id.secret_key_base.hex
      QueueUrl     = aws_sqs_queue.this_ui_fifo_queue.id
    }
  }
}

resource "aws_lambda_permission" "allow_trigger" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.this_batch_ingest.function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.this_dropbox.arn
}

resource "aws_s3_bucket_notification" "batch_ingest_notification" {
  bucket = aws_s3_bucket.this_dropbox.id

  lambda_function {
    lambda_function_arn = module.this_batch_ingest.function_arn
    filter_prefix       = "proquest/"
    filter_suffix       = ".zip"

    events = ["s3:ObjectCreated:*"]
  }
}

