data "aws_lambda_function" "iiif_image" {
  function_name = "iiif-image"
}

resource "aws_s3_bucket" "pyramid_tiff_bucket" {
  bucket = "${local.namespace}-pyramid-tiffs"
  acl    = "private"
  tags   = "${local.common_tags}"
}

data "aws_iam_policy_document" "pyramid_tiff_bucket_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["arn:aws:s3:::*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]

    resources = ["${aws_s3_bucket.pyramid_tiff_bucket.arn}"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]

    resources = ["${aws_s3_bucket.pyramid_tiff_bucket.arn}/*"]
  }
}

data "aws_iam_policy_document" "pyramid_bucket_public_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.pyramid_tiff_bucket.arn}/public/*"]

    principals {
      type        = "AWS"
      identifiers = ["${data.aws_lambda_function.iiif_image.role}"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.pyramid_tiff_bucket.arn}"]

    principals {
      type        = "AWS"
      identifiers = ["${data.aws_lambda_function.iiif_image.role}"]
    }
  }
}

resource "aws_s3_bucket_policy" "allow_cloudfront_pyramid_public_access" {
  bucket = "${aws_s3_bucket.pyramid_tiff_bucket.id}"
  policy = "${data.aws_iam_policy_document.pyramid_bucket_public_policy.json}"
}

resource "aws_lambda_permission" "iiif_gateway_lambda_access" {
  statement_id    = "AllowIIIFImageGatewayInvocation"
  action          = "lambda:InvokeFunction"
  function_name   = "iiif-image"
  principal       = "apigateway.amazonaws.com"
  source_arn      = "${aws_api_gateway_rest_api.iiif_api.execution_arn}/*/*/*"
}

data "template_file" "iiif_openapi_template" {
  template = "${file("./templates/iiif_api_gateway_openapi.json.tpl")}"

  vars {
    api_name              = "${local.namespace}-iiif"
    hostname              = "iiif.${local.public_zone_name}"
    lambda_arn            = "${data.aws_lambda_function.iiif_image.arn}"
    public_manifest_url   = "http://donut.${local.public_zone_name}"
    region                = "${var.aws_region}"
  }
}

resource "aws_api_gateway_rest_api" "iiif_api" {
  name                  = "${local.namespace}-iiif"
  description           = "Mini IIIF Server"
  binary_media_types    = ["*/*"]
  body                  = "${data.template_file.iiif_openapi_template.rendered}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "iiif_deployment" {
  rest_api_id   = "${aws_api_gateway_rest_api.iiif_api.id}"
  stage_name    = "latest"
}

resource "aws_api_gateway_stage" "iiif_latest" {
  stage_name    = "latest"
  rest_api_id   = "${aws_api_gateway_rest_api.iiif_api.id}"
  deployment_id = "${aws_api_gateway_deployment.iiif_deployment.id}"
}

resource "aws_api_gateway_domain_name" "iiif_domain_name" {
  count                       = "${var.iiif_ssl_certificate_arn == "" ? 0 : 1}"
  domain_name                 = "iiif.${local.public_zone_name}"
  regional_certificate_arn    = "${var.iiif_ssl_certificate_arn}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "iiif_domain_mapping" {
  base_path     = "/"
  api_id        = "${aws_api_gateway_rest_api.iiif_api.id}"
  stage_name    = "${aws_api_gateway_stage.iiif_latest.stage_name}"
  domain_name   = "${aws_api_gateway_domain_name.iiif_domain_name.domain_name}"
}

resource "aws_route53_record" "iiif" {
  zone_id = "${module.dns.public_zone_id}"
  name    = "iiif.${local.public_zone_name}"
  type    = "A"

  alias {
    name                   = "${aws_api_gateway_domain_name.iiif_domain_name.regional_domain_name}"
    zone_id                = "${aws_api_gateway_domain_name.iiif_domain_name.regional_zone_id}"
    evaluate_target_health = true
  }
}
