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
    puts "Processing:"
    puts JSON.pretty_generate(event)
    [201, 'Created', '']
  end
end