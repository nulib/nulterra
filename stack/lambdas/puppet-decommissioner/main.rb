require 'aws-sdk-ssm'
require 'aws-sdk-ec2'
require 'json'
require_relative './lib/decommissioner'

def handle_event(event:, context:)
  handler = LambdaHandler.new(event, context)
  handler.process!
end

class LambdaHandler
  attr_reader :event, :context
  
  def initialize(event, context)
    @event = event
    @context = context
  end
  
  def process!
    gordon.decommission(instance_certname)
  end
  
  def gordon
    @gordon ||= Decommissioner.new(*get_parameters('server', 'auth_cert', 'auth_key'))
  end

  def ssm
    @ssm ||= Aws::SSM::Client.new
  end

  def instance_certname
    return event['certname'] unless event['certname'].nil?
    instance_id = event['detail']['instance-id']
    instance = Aws::EC2::Instance.new(id: instance_id)
    instance.tags.find { |tag| tag.key == 'nul:puppet:certname' }&.value
  end

  def get_parameters(*names)
    names.collect { |name| get_parameter(name) }
  end

  def get_parameter(name)
    ssm.get_parameter(name: "/puppet/api/#{name}", with_decryption: true).parameter.value
  end
end
