require_relative "../command"
require_relative "../../checks/cloudwatch/vpc_endpoint_check"
require "aws-sdk-ec2"

class FindUnusedVpcEndpounts < Command
  def execute(context)
    each_region do |region|
      ec2_client = Aws::EC2::Client.new(region: region)
      vpc_endpoints = ec2_client.describe_vpc_endpoints.vpc_endpoints

      vpc_endpoints.each do |vpc_endpoint|
        result = vpc_endpoint_check.matches(context, region, vpc_endpoint.vpc_endpoint_type, vpc_endpoint.vpc_endpoint_id, vpc_endpoint.vpc_id, vpc_endpoint.service_name)
        if result
          context.logger.debug "Creating a finding for VPC endpoint #{vpc_endpoint.vpc_endpoint_id}"
          f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/ec2").find_or_create_by(
            issue_type: vpc_endpoint_check.issue_type,
            resource_id: vpc_endpoint.vpc_endpoint_id,
            account_id: context.aws_account_id
          ).tap do |f|
            f.region = region
            f.message = vpc_endpoint_check.message
            f.metadata = vpc_endpoint.to_h
            f.scan = context.scan
          end
          f.save!
        end
      end
    end
  end

  def vpc_endpoint_check
    VpcEndpointCheck.new(
      metric: "NewConnections",
      namespace: "AWS/PrivateLinkEndpoints",
      attribute: "VPC Endpoint Id",
      issue_type: "aws-ec2-vpc-endpoint-unused",
      statistic: "Sum",
      period: (24 * 60 * 60),
      message: "No new connections established in the time period."
    )
  end
end
