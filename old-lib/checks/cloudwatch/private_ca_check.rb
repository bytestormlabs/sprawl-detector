require_relative "./cloudwatch_check"

class PrivateCACheck < CloudWatchCheck
  def matches(context, region, private_ca_arn)
    context.logger.debug "entering check(metric = #{@metric}, statistics = #{@statistic}, private_ca_arn = #{private_ca_arn})"
    metric_statistics = retrieve_metric_statistics(region, [
      {name: "Operation", value: "IssueCertificate"},
      {name: "PrivateCAArn", value: private_ca_arn}
    ])
    context.logger.debug "Retrieved #{metric_statistics[:datapoints].length} data points."
    metrics_indicate_a_match?(metric_statistics)
  end
end
