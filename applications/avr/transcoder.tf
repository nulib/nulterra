resource "aws_sns_topic" "this_transcode_notification" {
  name = "${local.namespace}-pipeline-topic"
}

data "aws_iam_policy_document" "transcoder" {
  statement {
    sid     = ""
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["elastictranscoder.amazonaws.com"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "this_pipeline_role" {
  name               = "${local.namespace}-pipeline-role"
  assume_role_policy = "${data.aws_iam_policy_document.transcoder.json}"
}

data "aws_iam_policy_document" "this_pipeline_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:Put*",
      "s3:ListBucket",
      "s3:*MultipartUpload*",
      "s3:Get*",
    ]

    resources = [
      "${aws_s3_bucket.this_masterfiles.arn}",
      "${aws_s3_bucket.this_derivatives.arn}",
      "${aws_s3_bucket.this_masterfiles.arn}/*",
      "${aws_s3_bucket.this_derivatives.arn}/*",
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = ["${aws_sns_topic.this_transcode_notification.arn}"]
  }

  statement {
    effect = "Deny"

    actions = [
      "s3:*Delete*",
      "s3:*Policy*",
      "sns:*Remove*",
      "sns:*Delete*",
      "sns:*Permission*",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "this_pipeline_policy" {
  name   = "${local.namespace}-${local.app_name}-pipeline-policy"
  policy = "${data.aws_iam_policy_document.this_pipeline_policy.json}"
}

resource "aws_iam_role_policy_attachment" "this_pipeline" {
  role       = "${aws_iam_role.this_pipeline_role.name}"
  policy_arn = "${aws_iam_policy.this_pipeline_policy.arn}"
}

resource "aws_elastictranscoder_pipeline" "this_pipeline" {
  name          = "${local.namespace}-${local.app_name}-transcoding-pipeline"
  input_bucket  = "${aws_s3_bucket.this_masterfiles.id}"
  output_bucket = "${aws_s3_bucket.this_derivatives.id}"
  role          = "${aws_iam_role.this_pipeline_role.arn}"

  notifications {
    completed   = "${aws_sns_topic.this_transcode_notification.arn}"
    error       = "${aws_sns_topic.this_transcode_notification.arn}"
    progressing = "${aws_sns_topic.this_transcode_notification.arn}"
    warning     = "${aws_sns_topic.this_transcode_notification.arn}"
  }
}
