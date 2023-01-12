require "detector/support/cloudwatch"
require "aws-sdk-ec2"

class VpcWithoutS3Endpoint
  ISSUE_TYPE = "aws-ec2-vpc-without-s3-endpoint"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::EC2::Client.new(region: region, credentials: scan.credentials)
    client.describe_vpcs.vpcs.each do |vpc|

      resource = scan.build_resource(region, resource_type, vpc.vpc_id, vpc)
      vpc_endpoints = client.describe_vpc_endpoints(filters: [ {name: "vpc-id", values: [vpc.vpc_id]}]).vpc_endpoints

      # Look for the service name 'com.amazonaws.#{region}.s3'

      has_s3_endpoint = vpc_endpoints.any? do |vpc_endpoint|
        vpc_endpoint.service_name == "com.amazonaws.#{region}.s3"
      end

      resource.create_finding(scan, ISSUE_TYPE) unless has_s3_endpoint
    end
  end
  def service_name
    "EC2 - Other"
  end

  def resource_type
    "AWS::EC2::VPC"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
