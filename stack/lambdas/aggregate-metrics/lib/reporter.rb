require_relative './aggregator'

class Reporter
  attr_reader :aggregator

  METRICS = %w{ DockerDataUsedPct RootDeviceUsedPct MemoryBytesUsed MemoryBytesFree MemorySwapUsed MemorySwapFree }

  def initialize
    @aggregator = Aggregator.new
  end

  def collect
    aggregator.environments.collect do |env|
      METRICS.collect do |metric|
        aggregator.data(env, metric)
      end.reject { |datum| datum.values.empty? }
    end.flatten
  end

  def to_metric_data(data)
    data.collect do |datum|
      {
        metric_name: datum.metric,
        dimensions: [{ name: 'Environment', value: datum.environment }],
        timestamp: datum.timestamps.max,
        values: datum.values,
        unit: datum.unit || 'Bytes'
      }
    end
  end

  def data_groups(data)
    metric_data = to_metric_data(data)
    [].tap do |result|
      until metric_data.empty? do
        result << metric_data.take(20)
        metric_data = metric_data.drop(20)
      end
    end
  end

  def report(data)
    data_groups(data).each do |group|
      aggregator.client.put_metric_data({
        namespace: aggregator.namespace,
        metric_data: group
      })
    end
  end
end

