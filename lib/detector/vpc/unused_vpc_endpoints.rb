require "detector/support/cloudwatch"
require "aws-sdk-ec2"

class UnusedVpcEndpoints
  ISSUE_TYPE = "aws-ec2-vpc-endpoint-unused"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::EC2::Client.new(region: region, credentials: scan.credentials)
    client.describe_vpc_endpoints.vpc_endpoints.each do |vpc_endpoint|
      resource = scan.build_resource(region, resource_type, vpc_endpoint.vpc_endpoint_id, vpc_endpoint)

      number_of_days = 14   # TODO: Refactor this
      connections = check("AWS/PrivateLinkEndpoints", "NewConnections")
        .in(region)
        .in_last(number_of_days)
        .with_dimension("VPC Id", vpc_endpoint.vpc_id)
        .with_dimension("VPC Endpoint Id", vpc_endpoint.vpc_endpoint_id)
        .with_dimension("Endpoint Type", vpc_endpoint.vpc_endpoint_type)
        .with_dimension("Service Name", vpc_endpoint.service_name)
        .with(scan.credentials)
        .average.hourly

      pp connections

      resource.create_finding(scan, ISSUE_TYPE) if connections.indicates_zero_activity?
    end
  end

  def service_name
    "Amazon Virtual Private Cloud"
  end

  def resource_type
    "AWS::EC2::VPCEndpoint"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
