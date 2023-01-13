require_relative "./cloudwatch_check"

class ElbV2TargetGroupCheck < CloudWatchCheck
  def matches(context, region, target_group_id, load_balancer_id)
    context.logger.debug "entering check(metric = #{@metric}, statistics = #{@statistic}, target_group_id = #{target_group_id}, load_balancer_id = #{load_balancer_id})"
    metric_statistics = retrieve_metric_statistics(region, [
      {name: "TargetGroup", value: target_group_id},
      {name: "LoadBalancer", value: load_balancer_id}
    ])
    context.logger.debug "Retrieved #{metric_statistics[:datapoints].length} data points."
    metrics_indicate_a_match?(metric_statistics)
  end
end
