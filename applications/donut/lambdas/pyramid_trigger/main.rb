require 'aws-sdk-sqs'
require 'aws-sdk-s3'
require 'json'

require_relative './lib/task'

def handle_event(event:, context:)
  handler = LambdaHandler.new(event, context)
  handler.process!
end

class LambdaHandler
  attr_reader :event, :context, :pyramid_queue_url, :ecs, :pyramid_bucket, :destination_s3_key

  def initialize(event, context)
    @event = event
    @context = context
    @pyramid_queue_url = ENV['QueueUrl']
    @ecs = Task.new
    unless event['target'].nil?
      @pyramid_bucket = event['target'].split(/s3:\/\/(.*?)\//)[1]
      @destination_s3_key = event['target'].scan(/^s3:\/\/#{pyramid_bucket}\/(.+)$/).flatten.first
    end
  end

  def process!
    begin
      if event['target'].nil?
        return { statusCode: 200, body: JSON.generate('OK') } if ecs.task_running? 
        ecs.run_task if messages_waiting?
        { statusCode: 201, body: JSON.generate('Started...') }
      end
      return { statusCode: 304, body: JSON.generate('Not Modified') } if destination_exists?
    
      send_to_sqs
      ecs.run_task unless ecs.task_running?
      { statusCode: 201, body: JSON.generate('Created') }
    rescue StandardError => error
      puts error.backtrace.join("\n")
      { statusCode: 500, body: error.message }
    end
  end
  
  def messages_waiting?
    sqs = Aws::SQS::Client.new
    req = sqs.get_queue_attributes( { queue_url: pyramid_queue_url, attribute_names: ['ApproximateNumberOfMessages'] })
    req.attributes['ApproximateNumberOfMessages'].to_i.positive?
  end

  def send_to_sqs
    sqs = Aws::SQS::Client.new
    sqs.send_message(queue_url: pyramid_queue_url, message_body: JSON.generate(event))
  end

  def destination_exists?
    bucket = Aws::S3::Resource.new.bucket(pyramid_bucket)
    bucket.object(destination_s3_key).exists?
  end
end
