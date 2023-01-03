require_relative "./cloudwatch_check"

class VpcEndpointCheck < CloudWatchCheck

  def matches(context, region, endpoint_type, vpc_endpoint_id, vpc_id, service_name)
    context.logger.debug "entering check(metric = #{@metric}, statistics = #{@statistic}, endpoint_type = #{endpoint_type}, vpc_endpoint_id = #{vpc_endpoint_id})"
    metric_statistics = retrieve_metric_statistics(region, [
      {name: "Endpoint Type", value: endpoint_type },
      {name: "VPC Endpoint Id", value: vpc_endpoint_id },
      {name: "VPC Id", value: vpc_id },
      {name: "Service Name", value: service_name },
    ])
    pp metric_statistics
    context.logger.debug "Retrieved #{metric_statistics[:datapoints].length} data points."
    metrics_indicate_a_match?(metric_statistics)
  end
end
