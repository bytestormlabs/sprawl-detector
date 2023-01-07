require_relative "../command"
require_relative "../../checks/cloudwatch/cloudwatch_check"
require "aws-sdk-ec2"

class FindUnusedNatGateways < Command
  def execute(context)
    each_region do |region|
      ec2_client = Aws::EC2::Client.new(region: region)
      nat_gateways = ec2_client.describe_nat_gateways.nat_gateways

      nat_gateways.each do |nat_gateway|
        result = nat_gateway_check.matches(context, region, nat_gateway.nat_gateway_id)
        if result
          f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/ec2").find_or_create_by(
            issue_type: nat_gateway_check.issue_type,
            resource_id: nat_gateway.nat_gateway_id,
            aws_account_id: context.aws_account_id, account: Account.find_by_account_id(context.aws_account_id)
          ).tap do |f|
            f.region = region
            f.message = nat_gateway_check.message
            f.metadata = nat_gateway.to_h
            f.scan = context.scan
          end
          f.save!
        end
      end
    end
  end

  def nat_gateway_check
    CloudWatchCheck.new(
      metric: "ConnectionEstablishedCount",
      namespace: "AWS/NATGateway",
      attribute: "NatGatewayId",
      issue_type: "aws-ec2-nat-gateway-unused",
      period: 24 * 60 * 60,
      message: "No connections established in the last week."
    )
  end
end
