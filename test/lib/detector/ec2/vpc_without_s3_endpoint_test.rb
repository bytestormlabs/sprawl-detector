require "detector/ec2/vpc_without_s3_endpoint"
require "base_aws_integration_test"

class VpcWithoutS3EndpointTest < ActiveSupport::TestCase
  detector = VpcWithoutS3Endpoint.new

  test "has correct service name" do
    assert_equal detector.service_name, "EC2 - Other"
  end
  test "has correct resource type" do
    assert_equal detector.resource_type, "AWS::EC2::VPC"
  end
  test "generates default settings" do
    assert_equal detector.default_settings.count, 1
  end

  # class IntegrationTests < BaseAwsIntegrationTest
  #   detector = VpcWithoutS3Endpoint.new
  #
  #   test "create resources" do
  #     scan = Scan.create(account: Account.first, credentials: Aws::SharedCredentials.new)
  #     findings = Finding.count
  #     detector.execute(scan, "us-east-2")
  #     assert findings < Finding.count
  #   end
  # end
end
