resource "aws_lambda_layer_version" "common_layer" {
  filename              = "${path.module}/../lambda_layers/build/common.zip"
  source_code_hash      = "${base64sha256(file("${path.module}/../lambda_layers/build/common.zip"))}"
  layer_name            = "${local.namespace}-js-common"
  compatible_runtimes   = ["nodejs12.x"]
  description           = "Common modules for nodejs lambdas"
}

resource "aws_lambda_layer_version" "image_utils_layer" {
  filename              = "${path.module}/../lambda_layers/build/image-utils.zip"
  source_code_hash      = "${base64sha256(file("${path.module}/../lambda_layers/build/image-utils.zip"))}"
  layer_name            = "${local.namespace}-js-image-utils"
  compatible_runtimes   = ["nodejs12.x"]
  description           = "Image processing modules for nodejs lambdas"
}