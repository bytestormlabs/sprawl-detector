require_relative "../../checks/cloudwatch/elbv2_target_group_check"
require_relative "../../checks/cloudwatch/cloudwatch_check"
require_relative "../command"
require "aws-sdk-elasticloadbalancingv2"
require "date"

class FindUnusedTargetGroups < Command
  def execute(context)
    each_region do |region|
      elb_client = Aws::ElasticLoadBalancingV2::Client.new(region: region)
      target_groups = elb_client.describe_target_groups.target_groups

      target_groups.each do |target_group|
        if target_group.load_balancer_arns.empty?
          f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/elbv2").find_or_create_by(
            issue_type: request_count_check.issue_type,
            resource_id: target_group.target_group_name,
            aws_account_id: context.aws_account_id, account: Account.find_by_account_id(context.aws_account_id)
          ).tap do |f|
            f.region = region
            f.message = "Target group is not associated with a load balancer."
            f.metadata = target_group.to_h
            f.scan = context.scan
          end
          f.save!
        else

          protocol = target_group.protocol

          if protocol == "HTTP"
            check_application_elb_target_group(context, region, target_group)
          elsif protocol == "TCP"
            check_network_lb_target_group(context, region, target_group)
          end
        end
      end
    end
  end

  def check_application_elb_target_group(context, region, target_group)
    target_group_name = target_group.target_group_arn.split(":").last
    load_balancer_name = target_group.load_balancer_arns.first.split(":").last.gsub("loadbalancer/", "")
    matches = request_count_check.matches(context, region, target_group_name, load_balancer_name)

    return if !matches

    f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/elbv2").find_or_create_by(
      issue_type: request_count_check.issue_type,
      resource_id: target_group.target_group_name,
      aws_account_id: context.aws_account_id, account: Account.find_by_account_id(context.aws_account_id)
    ).tap do |f|
      f.region = region
      f.message = request_count_check.message
      f.metadata = target_group.to_h
      f.scan = context.scan
    end
    f.save!
  end

  def check_network_lb_target_group(context, region, target_group)
    target_group_name = target_group.target_group_arn.split(":").last
    load_balancer_name = target_group.load_balancer_arns.first.split(":").last.gsub("loadbalancer/", "")
    matches = healthy_host_count_check.matches(context, region, target_group_name, load_balancer_name)

    return if !matches

    f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/elbv2").find_or_create_by(
      issue_type: healthy_host_count_check.issue_type,
      resource_id: target_group.target_group_name,
      aws_account_id: context.aws_account_id, account: Account.find_by_account_id(context.aws_account_id)
    ).tap do |f|
      f.region = region
      f.message = healthy_host_count_check.message
      f.metadata = target_group.to_h
      f.scan = context.scan
    end
    f.save!

    healthy_host_count_check
  end

  def request_count_check
    ElbV2TargetGroupCheck.new(
      metric: "RequestCount",
      issue_type: "aws-elbv2-target-group-unused",
      statistic: "Sum",
      attribute: "TargetGroup",
      namespace: "AWS/ApplicationELB",
      period: (60 * 60),
      message: "Target group has received 0 requests in time period"
    )
  end

  def healthy_host_count_check
    ElbV2TargetGroupCheck.new(
      metric: "HealthyHostCount",
      issue_type: "aws-elbv2-target-group-unused",
      statistic: "Sum",
      attribute: "TargetGroup",
      namespace: "AWS/NetworkELB",
      period: (60 * 60),
      message: "Target group has 0 healthy hosts during the time period."
    )
  end
end
