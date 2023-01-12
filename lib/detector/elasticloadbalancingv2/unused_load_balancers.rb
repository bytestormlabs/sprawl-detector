require "detector/support/cloudwatch"
require "aws-sdk-elasticloadbalancingv2"

class UnusedLoadBalancers
  ISSUE_TYPE = "issuetype"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::ElasticLoadBalancingV2::Client.new(region: region, credentials: scan.credentials)
    loop_until_finished(client, :describe_load_balancers) do |response|
      response.load_balancers.each do |load_balancer|

        number_of_days = 14   # TODO: Refactor this
        type = load_balancer["type"]
        load_balancer_name = load_balancer.load_balancer_arn.split(":").last.gsub("loadbalancer/", "")

        target_date = (DateTime.now - 14)

        if type == "application"
          resource = scan.build_resource(region, "AWS::ElasticLoadBalancingV2::LoadBalancer", load_balancer.load_balancer_arn, load_balancer)
          request_count = check("AWS/ApplicationELB", "RequestCount")
            .in(region)
            .in_last(number_of_days)
            .with_dimension("LoadBalancer", load_balancer_name)
            .with(scan.credentials)

          resource.create_finding(scan, ISSUE_TYPE) if load_balancer.created_time < target_date && request_count.indicates_zero_activity?
        elsif type == "network"
          resource = scan.build_resource(region, "AWS::ElasticLoadBalancingV2::LoadBalancer", load_balancer.load_balancer_arn, load_balancer)
          active_flow_count = check("AWS/NetworkELB", "ActiveFlowCount")
            .in(region)
            .in_last(number_of_days)
            .with_dimension("LoadBalancer", load_balancer_name)
            .with(scan.credentials)

          resource.create_finding(scan, ISSUE_TYPE) if load_balancer.created_time < target_date && active_flow_count.indicates_zero_activity?
        elsif type == "classic"
          resource = scan.build_resource(region, "AWS::ElasticLoadBalancing::LoadBalancer", load_balancer.load_balancer_arn, load_balancer)
          request_count_check = check("AWS/ELB", "RequestCount")
            .in(region)
            .in_last(number_of_days)
            .with_dimension("LoadBalancerName", load_balancer_name)
            .with(scan.credentials)

          resource.create_finding(scan, ISSUE_TYPE) if load_balancer.created_time < target_date && request_count_check.indicates_zero_activity?
        end
      end
    end
  end
  def service_name
    "Amazon Elastic Load Balancing"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
