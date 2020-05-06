module "iiif_function" {
  source = "git://github.com/nulib/terraform-aws-lambda"

  function_name = "${local.namespace}-iiif"
  description   = "IIIF Image server lambda"
  handler       = "index.handler"
  runtime       = "nodejs12.x"
  memory_size   = 3008
  timeout       = 300

  attach_policy = true
  policy        = "${data.aws_iam_policy_document.pyramid_tiff_bucket_access.json}"

  environment {
    variables {
      VIPS_DISC_THRESHOLD = "1500m"
      allow_from          = "${local.allow_from}"
      api_token_secret    = "${var.api_token_secret}"
      auth_domain         = "${var.hosted_zone_name}"
      elastic_search      = "https://${aws_elasticsearch_domain.elasticsearch.endpoint}/"
      tiff_bucket         = "${aws_s3_bucket.pyramid_tiff_bucket.id}"
    }
  }

  layers = [
    "${aws_lambda_layer_version.common_layer.layer_arn}:${aws_lambda_layer_version.common_layer.version}",
    "${aws_lambda_layer_version.image_utils_layer.layer_arn}:${aws_lambda_layer_version.image_utils_layer.version}",
  ]

  source_path   = "${path.module}/lambdas/iiif"
  build_command = "${path.module}/../bin/bundle-lambda '$$filename' '$$runtime' '$$source' common image-utils"
  tags          = "${local.common_tags}"

  reserved_concurrent_executions = "-1"
}

resource "aws_s3_bucket" "pyramid_tiff_bucket" {
  bucket = "${local.namespace}-pyramid-tiffs"
  acl    = "private"
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = ["x-amz-server-side-encryption", "x-amz-request-id", "x-amz-id-2"]
    max_age_seconds = 3000
  }
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
      identifiers = ["${module.iiif_function.role_arn}"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.pyramid_tiff_bucket.arn}"]

    principals {
      type        = "AWS"
      identifiers = ["${module.iiif_function.role_arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "allow_cloudfront_pyramid_public_access" {
  bucket = "${aws_s3_bucket.pyramid_tiff_bucket.id}"
  policy = "${data.aws_iam_policy_document.pyramid_bucket_public_policy.json}"
}

data "template_file" "iiif_openapi_template" {
  template = "${file("./templates/iiif_api_gateway_openapi.yaml.tpl")}"

  vars {
    api_name            = "${local.namespace}-iiif"
    hostname            = "iiif.${local.public_zone_name}"
    lambda_arn          = "${replace(module.iiif_function.function_arn, ":$LATEST", "")}"
    public_manifest_url = "http://donut.${local.public_zone_name}"
    region              = "${var.aws_region}"
  }
}

resource "aws_api_gateway_rest_api" "iiif_api" {
  name               = "${local.namespace}-iiif"
  description        = "Mini IIIF Server"
  binary_media_types = ["*/*"]
  body               = "${data.template_file.iiif_openapi_template.rendered}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "iiif_deployment" {
  rest_api_id = "${aws_api_gateway_rest_api.iiif_api.id}"
  stage_name  = "latest"
}

resource "aws_api_gateway_stage" "iiif_latest" {
  stage_name            = "latest"
  rest_api_id           = "${aws_api_gateway_rest_api.iiif_api.id}"
  deployment_id         = "${aws_api_gateway_deployment.iiif_deployment.id}"
  cache_cluster_enabled = "true"
  cache_cluster_size    = "0.5"
}

resource "aws_api_gateway_domain_name" "iiif_domain_name" {
  count                    = "${var.iiif_ssl_certificate_arn == "" ? 0 : 1}"
  domain_name              = "iiif.${local.public_zone_name}"
  regional_certificate_arn = "${var.iiif_ssl_certificate_arn}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "iiif_domain_mapping" {
  count       = "${var.iiif_ssl_certificate_arn == "" ? 0 : 1}"
  base_path   = ""
  api_id      = "${aws_api_gateway_rest_api.iiif_api.id}"
  stage_name  = "${aws_api_gateway_stage.iiif_latest.stage_name}"
  domain_name = "${aws_api_gateway_domain_name.iiif_domain_name.domain_name}"
}

resource "aws_route53_record" "iiif" {
  count   = "${var.iiif_ssl_certificate_arn == "" ? 0 : 1}"
  zone_id = "${module.dns.public_zone_id}"
  name    = "iiif.${local.public_zone_name}"
  type    = "A"

  alias {
    name                   = "${aws_api_gateway_domain_name.iiif_domain_name.regional_domain_name}"
    zone_id                = "${aws_api_gateway_domain_name.iiif_domain_name.regional_zone_id}"
    evaluate_target_health = true
  }
}

locals {
  allow_from         = "${var.allow_iiif_from == "" ? "${replace("donut.${local.public_zone_name}", ".", "\\.")};${replace("meadow.${var.hosted_zone_name}", ".", "\\.")}" : "${var.allow_iiif_from}"}"
  fudged_record_list = "${concat(aws_route53_record.iiif.*.name, list("DUMMY_ITEM"))}"
  iiif_base_url      = "${length(aws_route53_record.iiif.*.name) > 0 ? "https://${element(local.fudged_record_list, 0)}/" : aws_api_gateway_stage.iiif_latest.invoke_url}"
}
