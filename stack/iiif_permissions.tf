resource "aws_lambda_permission" "iiif_gateway_lambda_access_36e6eb545" {
  depends_on      = []
  statement_id    = "36e6eb545"
  action          = "lambda:InvokeFunction"
  function_name   = "${data.aws_lambda_function.iiif_image.function_name}"
  principal       = "apigateway.amazonaws.com"
  source_arn      = "${aws_api_gateway_rest_api.iiif_api.execution_arn}/*/POST/iiif/login"
}
resource "aws_lambda_permission" "iiif_gateway_lambda_access_55592c830" {
  depends_on      = ["aws_lambda_permission.iiif_gateway_lambda_access_36e6eb545"]
  statement_id    = "55592c830"
  action          = "lambda:InvokeFunction"
  function_name   = "${data.aws_lambda_function.iiif_image.function_name}"
  principal       = "apigateway.amazonaws.com"
  source_arn      = "${aws_api_gateway_rest_api.iiif_api.execution_arn}/*/OPTIONS/iiif/login"
}
resource "aws_lambda_permission" "iiif_gateway_lambda_access_31ca4be7f" {
  depends_on      = ["aws_lambda_permission.iiif_gateway_lambda_access_55592c830"]
  statement_id    = "31ca4be7f"
  action          = "lambda:InvokeFunction"
  function_name   = "${data.aws_lambda_function.iiif_image.function_name}"
  principal       = "apigateway.amazonaws.com"
  source_arn      = "${aws_api_gateway_rest_api.iiif_api.execution_arn}/*/GET/iiif/2/{id}/{proxy+}"
}
resource "aws_lambda_permission" "iiif_gateway_lambda_access_45ea391bb" {
  depends_on      = ["aws_lambda_permission.iiif_gateway_lambda_access_31ca4be7f"]
  statement_id    = "45ea391bb"
  action          = "lambda:InvokeFunction"
  function_name   = "${data.aws_lambda_function.iiif_image.function_name}"
  principal       = "apigateway.amazonaws.com"
  source_arn      = "${aws_api_gateway_rest_api.iiif_api.execution_arn}/*/OPTIONS/iiif/2/{id}/{proxy+}"
}
resource "aws_lambda_permission" "iiif_gateway_lambda_access_552cfb3a3" {
  depends_on      = ["aws_lambda_permission.iiif_gateway_lambda_access_45ea391bb"]
  statement_id    = "552cfb3a3"
  action          = "lambda:InvokeFunction"
  function_name   = "${data.aws_lambda_function.iiif_image.function_name}"
  principal       = "apigateway.amazonaws.com"
  source_arn      = "${aws_api_gateway_rest_api.iiif_api.execution_arn}/*/GET/iiif/2/{id}"
}
resource "aws_lambda_permission" "iiif_gateway_lambda_access_86ccd59d1" {
  depends_on      = ["aws_lambda_permission.iiif_gateway_lambda_access_552cfb3a3"]
  statement_id    = "86ccd59d1"
  action          = "lambda:InvokeFunction"
  function_name   = "${data.aws_lambda_function.iiif_image.function_name}"
  principal       = "apigateway.amazonaws.com"
  source_arn      = "${aws_api_gateway_rest_api.iiif_api.execution_arn}/*/OPTIONS/iiif/2/{id}"
}
resource "aws_lambda_permission" "iiif_gateway_lambda_access_f58cf1054" {
  depends_on      = ["aws_lambda_permission.iiif_gateway_lambda_access_86ccd59d1"]
  statement_id    = "f58cf1054"
  action          = "lambda:InvokeFunction"
  function_name   = "${data.aws_lambda_function.iiif_image.function_name}"
  principal       = "apigateway.amazonaws.com"
  source_arn      = "${aws_api_gateway_rest_api.iiif_api.execution_arn}/*/GET/iiif/2/{id}/info.json"
}
resource "aws_lambda_permission" "iiif_gateway_lambda_access_e6d5e1923" {
  depends_on      = ["aws_lambda_permission.iiif_gateway_lambda_access_f58cf1054"]
  statement_id    = "e6d5e1923"
  action          = "lambda:InvokeFunction"
  function_name   = "${data.aws_lambda_function.iiif_image.function_name}"
  principal       = "apigateway.amazonaws.com"
  source_arn      = "${aws_api_gateway_rest_api.iiif_api.execution_arn}/*/OPTIONS/iiif/2/{id}/info.json"
}
resource "null_resource" "aws_lambda_permissions" {
  depends_on      = ["aws_lambda_permission.iiif_gateway_lambda_access_e6d5e1923"]
}