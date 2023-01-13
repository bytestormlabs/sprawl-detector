class CloudWatchCheck
  attr_accessor :metric, :namespace, :statistic, :attribute, :period
  attr_accessor :issue_type, :message

  def initialize(opts = {})
    @metric = opts.fetch(:metric) { raise "Argument 'metric' is required." }
    @issue_type = opts.fetch(:issue_type) { raise "Argument 'issue_type' is required." }
    @attribute = opts.fetch(:attribute) { raise "Argument 'attribute' is required." }
    @statistic = opts.fetch(:statistic, "Average")
    @namespace = opts.fetch(:namespace, "")
    @predicate = opts.fetch(:predicate, proc { |value| value < 0.9 })
    @key = @statistic.downcase.to_sym
    @period = opts.fetch(:period, (60 * 60)) # Defaults to hourly
    @message = opts.fetch(:message, "#{@statistic} #{@metric}")
    @start_time = opts.fetch(:start_time, (DateTime.now - 14).to_s)
  end

  def matches(context, region, resource_id)
    context.logger.debug "entering check(metric = #{@metric}, statistics = #{@statistic}, resource_id = #{resource_id})"
    metric_statistics = retrieve_metric_statistics(region, [{name: @attribute, value: resource_id}])
    context.logger.debug "Retrieved #{metric_statistics[:datapoints].length} data points."

    received_zero_results(metric_statistics) || metrics_indicate_a_match?(metric_statistics)
  end

  def retrieve_metric_statistics(region, dimensions)
    client = Aws::CloudWatch::Client.new(region: region)
    client.get_metric_statistics(
      metric_name: @metric,
      namespace: @namespace,
      statistics: [@statistic],
      start_time: @start_time,
      end_time: DateTime.now.to_s,
      period: @period,
      dimensions: dimensions
    )
  end

  def received_zero_results(metric_statistics)
    metric_statistics[:datapoints].length == 0
  end

  def metrics_indicate_a_match?(metric_statistics)
    metric_statistics[:datapoints].map { |datapoint|
      datapoint[@key]
    }.all? @predicate
  end
end
