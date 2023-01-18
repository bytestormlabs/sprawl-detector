require "detector/vpc/unused_vpc_endpoints"
require "base_aws_integration_test"

class UnusedVpcEndpointsTest < ActiveSupport::TestCase
  detector = UnusedVpcEndpoints.new

  test "has correct service name" do
    assert_equal detector.service_name, "Amazon Virtual Private Cloud"
  end
  test "has correct resource type" do
    assert_equal detector.resource_type, "AWS::EC2::VPCEndpoint"
  end
  test "generates default settings" do
    assert_equal detector.default_settings.count, 1
  end

  # class IntegrationTests < BaseAwsIntegrationTest
  #   detector = UnusedVpcEndpoints.new
  #
  #   test "create resources" do
  #     scan = Scan.create(account: Account.first, credentials: Aws::SharedCredentials.new)
  #     before = Finding.count
  #     detector.execute(scan, "us-east-1")
  #     assert_equal before + 5, Finding.count
  #   end
  # end
end
