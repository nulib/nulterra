require 'aws-sdk-ec2'
require 'json'

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
    return false if instance.tags.find { |tag| tag.key == 'nul:puppet:certname' }
    response = instance.create_tags({
      tags: [{ key: 'nul:puppet:certname', value: instance_certname }]
    })
    {}.tap do |result|
      response.each do |tag|
        result[tag.key] = tag.value
      end
    end
  end

  def instance
    instance_id = event['detail']['instance-id']
    Aws::EC2::Instance.new(id: instance_id)
  end

  def name_tag
    instance.tags.find { |tag| tag.key == 'Name' }.value
  end

  def instance_certname
    sleep 2 while name_tag.empty? # lambda will kill this if it doesn't complete within its configured timeout
    attributes = name_tag.split(/-/, 4)
    namespace = attributes[0..1].compact.join('-')
    role = attributes[2..3].compact.join('-')
    dns_name = instance.private_dns_name.split(/\./).first
    "%s.%s.%s.nul.internal" % [dns_name, role, namespace]
  end
end
