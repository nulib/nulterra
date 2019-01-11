require 'forwardable'

class MetricData
  extend Forwardable
  attr_accessor :environment, :metric, :unit, :timestamps, :values
  def_delegators :@values, :min, :max

  def initialize(environment, metric, unit)
    @environment = environment
    @metric = metric
    @unit = unit
    @timestamps = []
    @values = []
  end

  def sum
    values.inject(0) { |sum, el| sum += el }
  end

  def average
    sum.to_f / values.size
  end
end

