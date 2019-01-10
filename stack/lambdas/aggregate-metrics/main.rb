require_relative './lib/reporter'

class LambdaHandler
  class << self
    def reporter
      @reporter ||= Reporter.new
    end

    def debug
      reporter.data_groups(reporter.collect)
    end

    def process(event:, context:)
      reporter.report(reporter.collect)
    end
  end
end