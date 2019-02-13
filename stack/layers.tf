resource "aws_lambda_layer_version" "common_layer" {
  filename              = "${path.module}/../lambda_layers/build/common.zip"
  layer_name            = "${local.namespace}-js-common"
  compatible_runtimes   = ["nodejs8.10"]
  description           = "Common modules for nodejs lambdas"
}

resource "aws_lambda_layer_version" "image_utils_layer" {
  filename              = "${path.module}/../lambda_layers/build/image-utils.zip"
  layer_name            = "${local.namespace}-js-image-utils"
  compatible_runtimes   = ["nodejs8.10"]
  description           = "Image processing modules for nodejs lambdas"
}