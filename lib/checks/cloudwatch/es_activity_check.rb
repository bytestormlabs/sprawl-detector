require_relative "./cloudwatch_check"

class EsActivityCheck < CloudWatchCheck
  def matches(context, region, domain_name)
    context.logger.debug "entering check(metric = #{@metric}, statistics = #{@statistic}, domain_name = #{domain_name})"
    metric_statistics = retrieve_metric_statistics(region, [
      {name: "DomainName", value: domain_name},
      {name: "ClientId", value: context.aws_account_id}
    ])
    context.logger.debug "Retrieved #{metric_statistics[:datapoints].length} data points."
    metrics_indicate_a_match?(metric_statistics)
  end
end
