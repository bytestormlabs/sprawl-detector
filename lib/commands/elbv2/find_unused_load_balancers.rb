require_relative "../../checks/cloudwatch/cloudwatch_check"
require_relative "../command"
require "aws-sdk-elasticloadbalancingv2"
require "date"

class FindUnusedLoadBalancers < Command
  def execute(context)
    each_region do |region|
      elb_client = Aws::ElasticLoadBalancingV2::Client.new(region: region)
      load_balancers = elb_client.describe_load_balancers.load_balancers

      load_balancers.each do |load_balancer|
        type = load_balancer["type"]

        if type == "application"
          check_application_load_balancer(context, region, load_balancer)
        elsif type == "network"
          check_network_load_balancer(context, region, load_balancer)
        elsif type == "classic"
          classic_lb_request_count_check(context, region, load_balancer)
        else
          raise "Unidentified lb type #{type}"
        end
      end
    end
  end

  def classic_lb_request_count_check(context, region, load_balancer)
    load_balancer_name = load_balancer.load_balancer_arn.split(":").last.gsub("loadbalancer/", "")
    matches = request_count_check.matches(context, region, load_balancer_name)

    context.logger.debug "Checking classic load balancer #{load_balancer_name}..."

    return if !matches

    context.logger.debug "Creating a finding."
    f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/elb").find_or_create_by(
      issue_type: classic_lb_request_count_check.issue_type,
      resource_id: load_balancer_name,
      account_id: context.aws_account_id
    ).tap do |f|
      f.region = region
      f.message = classic_lb_request_count_check.message
      f.metadata = load_balancer.to_h
      f.scan = context.scan
    end
    f.save!
  end

  def check_application_load_balancer(context, region, load_balancer)
    load_balancer_name = load_balancer.load_balancer_arn.split(":").last.gsub("loadbalancer/", "")
    matches = request_count_check.matches(context, region, load_balancer_name)

    return if !matches

    f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/elbv2").find_or_create_by(
      issue_type: request_count_check.issue_type,
      resource_id: load_balancer_name,
      account_id: context.aws_account_id
    ).tap do |f|
      f.region = region
      f.message = request_count_check.message
      f.metadata = load_balancer.to_h
      f.scan = context.scan
    end
    f.save!
  end

  def classic_lb_request_count_check
    CloudWatchCheck.new(
      metric: "RequestCount",
      issue_type: "aws-elb-classic-load-balancer-unused",
      statistic: "Sum",
      attribute: "LoadBalancerName",
      namespace: "AWS/ELB",
      period: (60 * 60 * 24),
      message: "Classic Load Balancer has received 0 requests in time period"
    )
  end

  def request_count_check
    CloudWatchCheck.new(
      metric: "RequestCount",
      issue_type: "aws-elbv2-load-balancer-unused",
      statistic: "Sum",
      attribute: "LoadBalancer",
      namespace: "AWS/ApplicationELB",
      period: (60 * 60 * 24),
      message: "Application Load Balancer has received 0 requests in time period"
    )
  end

  def check_network_load_balancer(context, region, load_balancer)
    load_balancer_name = load_balancer.load_balancer_arn.split(":").last.gsub("loadbalancer/", "")
    matches = active_flow_count_check.matches(context, region, load_balancer_name)

    return if !matches

    f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/elbv2").find_or_create_by(
      issue_type: active_flow_count_check.issue_type,
      resource_id: load_balancer_name,
      account_id: context.aws_account_id
    ).tap do |f|
      f.region = region
      f.message = active_flow_count_check.message
      f.metadata = load_balancer.to_h
      f.scan = context.scan
    end
    f.save!
  end

  def active_flow_count_check
    CloudWatchCheck.new(
      metric: "ActiveFlowCount",
      issue_type: "aws-elbv2-network-load-balancer-unused",
      statistic: "Sum",
      attribute: "LoadBalancer",
      namespace: "AWS/NetworkELB",
      period: (60 * 60 * 24),
      message: "Network Load Balancer has received 0 active flows in time period"
    )
  end
end
