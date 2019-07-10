resource "aws_lambda_layer_version" "common_layer" {
  filename              = "${path.module}/../lambda_layers/build/common.zip"
  source_code_hash      = "${base64sha256(file("${path.module}/../lambda_layers/build/common.zip"))}"
  layer_name            = "${local.namespace}-js-common"
  compatible_runtimes   = ["nodejs8.10"]
  description           = "Common modules for nodejs lambdas"
  tags                  = "${merge(local.common_tags, map("Name", "${local.namespace}-common_layer_lambda"))}"
}

resource "aws_lambda_layer_version" "image_utils_layer" {
  filename              = "${path.module}/../lambda_layers/build/image-utils.zip"
  source_code_hash      = "${base64sha256(file("${path.module}/../lambda_layers/build/image-utils.zip"))}"
  layer_name            = "${local.namespace}-js-image-utils"
  compatible_runtimes   = ["nodejs8.10"]
  description           = "Image processing modules for nodejs lambdas"
  tags                  = "${merge(local.common_tags, map("Name", "${local.namespace}-images_utils_layer_lambda"))}"
}