require "detector/support/cloudwatch"
require "aws-sdk-elasticloadbalancing"

class UnusedClassicLoadBalancers
  ISSUE_TYPE = "aws-elb-unused-load-balancer"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::ElasticLoadBalancing::Client.new(region: region, credentials: scan.credentials)
    loop_until_finished(client, :describe_load_balancers) do |response|
      number_of_days = 14 # TODO: Refactor me!
      target_date = (DateTime.now - number_of_days)
      response.load_balancer_descriptions.each do |load_balancer|
        resource = scan.build_resource(region, "AWS::ElasticLoadBalancing::LoadBalancer", load_balancer.load_balancer_name, load_balancer)
        request_count_check = check("AWS/ELB", "RequestCount")
          .in(region)
          .in_last(number_of_days)
          .with_dimension("LoadBalancerName", load_balancer.load_balancer_name)
          .with(scan.credentials)

        resource.create_finding(scan, ISSUE_TYPE) if load_balancer.created_time < target_date && request_count_check.indicates_zero_activity?
      end
    end
  end

  def service_name
    "Amazon Elastic Load Balancing"
  end

  def resource_type
    "AWS::ElasticLoadBalancing::LoadBalancer"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
