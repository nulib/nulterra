#!/usr/bin/env ruby

require 'digest/sha1'
require 'yaml'

api = YAML.load(File.read(File.expand_path('../../stack/templates/iiif_api_gateway_openapi.yaml.tpl', __FILE__)))
paths = []

api['paths'].each_pair do |path, methods|
  methods.each_pair do |method, integration|
    if integration['x-amazon-apigateway-integration']['type'] == 'aws_proxy'
      method_name = method == 'x-amazon-apigateway-any-method' ? 'ANY' : method.upcase
      paths << File.join(method_name, path)
    end
  end
end

dependency = '[]'
paths.each do |path|
  path_hash = (Digest::SHA1.new << path).to_s[0..8]
  $stdout.write <<__EOF__
resource "aws_lambda_permission" "iiif_gateway_lambda_access_#{path_hash}" {
  depends_on      = #{dependency}
  statement_id    = "#{path_hash}"
  action          = "lambda:InvokeFunction"
  function_name   = "${data.aws_lambda_function.iiif_image.function_name}"
  principal       = "apigateway.amazonaws.com"
  source_arn      = "${aws_api_gateway_rest_api.iiif_api.execution_arn}/*/#{path}"
}
__EOF__
  dependency = %{["aws_lambda_permission.iiif_gateway_lambda_access_#{path_hash}"]}
end

$stdout.write <<__EOF__
resource "null_resource" "aws_lambda_permissions" {
  depends_on      = #{dependency}
}
__EOF__