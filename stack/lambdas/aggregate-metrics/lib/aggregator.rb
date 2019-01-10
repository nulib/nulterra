require 'aws-sdk-cloudwatch'
require 'ostruct'
require_relative './metric_data'

class Aggregator
  attr_reader :client, :namespace

  UNITS = {
    'DockerDataUsedPct' => 'Percent',
    'RootDeviceUsedPct' => 'Percent'
  }
  
  def initialize(namespace: 'NUL')
    @client = Aws::CloudWatch::Client.new
    @namespace = namespace
  end

  def environments
    metrics.keys
  end

  def metric_names(environment)
    metrics[environment].keys
  end

  def metrics
    if @metrics.nil?
      all_metrics = [].tap do |result|
        response = @client.list_metrics(namespace: @namespace, dimensions: [{name: 'Environment'},{name: 'InstanceId'}], token: nil)
        while response
          token = response.next_token
          result.concat(response.metrics)
          response = token.nil? ? nil : @client.list_metrics(namespace: @namespace, dimensions: [{name: 'Environment'},{name: 'InstanceId'}], token: token)
        end
      end

      @metrics = all_metrics.group_by { |metric| metric.dimensions.find { |d| d.name == 'Environment' }.value }
      @metrics.each_pair do |env, metrics|
        @metrics[env] = metrics.group_by { |metric| metric.metric_name }
        @metrics[env].each_pair do |metric_name, metrics|
          @metrics[env][metric_name] = metrics.collect { |m| m.dimensions.find { |d| d.name == 'InstanceId' }.value }
          @metrics[env][metric_name].reject! { |m| m == 'all' }
        end
      end
    end
    @metrics
  end

  def queries_for(environment, metric)
    instances = metrics[environment][metric]
    instances.collect.with_index do |instance, index|
      {
        id: "metric_#{index}",
        metric_stat: {
          metric: {
            namespace: @namespace,
            metric_name: metric,
            dimensions: [
              {
                name: "Environment",
                value: environment
              },
              {
                name: "InstanceId",
                value: instance
              },
            ],
          },
          period: 60,
          stat: "Average",
          unit: UNITS[metric] || 'Bytes'
        }
      }
    end
  end

  def raw_data(environment, metric)
    unless environments.include?(environment) && metric_names(environment).include?(metric)
      return OpenStruct.new(metric_data_results: [])
    end

    client.get_metric_data(
      metric_data_queries: queries_for(environment, metric), 
      start_time: Time.now-60, 
      end_time: Time.now, 
      max_datapoints: 3
    )
  end

  def data(environment, metric)
    MetricData.new(environment, metric, UNITS[metric]).tap do |result|
      raw_data(environment, metric).metric_data_results.collect(&:to_h).each do |hash|
        result.timestamps.concat(Array(hash[:timestamps]))
        result.values.concat(Array(hash[:values]))
      end
    end
  end
end