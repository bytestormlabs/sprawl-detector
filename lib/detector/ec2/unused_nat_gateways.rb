require "detector/support/cloudwatch"
require "aws-sdk-ec2"

class UnusedNatGateways
  ISSUE_TYPE = "aws-ec2-nat-gateway-unused"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::EC2::Client.new(region: region, credentials: scan.credentials)

    client.describe_nat_gateways.nat_gateways.each do |nat_gateway|
      number_of_days = 14
      resource = scan.build_resource(region, resource_type, nat_gateway.nat_gateway_id, nat_gateway)
      success = check("AWS/NATGateway", "ConnectionEstablishedCount")
        .in(region)
        .in_last(number_of_days)
        .with_dimension("NatGatewayId", nat_gateway.nat_gateway_id)
        .with(scan.credentials)

      resource.create_finding(ISSUE_TYPE) if success.indicates_zero_activity?
    end
  end
  def service_name
    "EC2 - Other"
  end

  def resource_type
    "AWS::EC2::NatGateway"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
