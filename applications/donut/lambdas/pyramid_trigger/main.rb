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
    @pyramid_bucket = event[:target].split(/s3:\/\/(.*?)\//)[1]
    @destination_s3_key = event[:target].scan(/^s3:\/\/#{pyramid_bucket}\/(.+)$/).flatten.first
  end

  def process!
    return { statusCode: 304, body: JSON.generate('Not Modified') } if destination_exists?
    begin
      send_to_sqs
      ecs.run_task unless ecs.task_running?
      { statusCode: 201, body: JSON.generate('Created') }
    rescue StandardError => error
      { statusCode: 500, body: JSON.generate(error.message) }
    end
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
