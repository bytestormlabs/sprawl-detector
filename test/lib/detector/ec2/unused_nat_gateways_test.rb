require "detector/ec2/unused_nat_gateways"
require "base_aws_integration_test"

class UnusedNatGatewaysTest < ActiveSupport::TestCase
  detector = UnusedNatGateways.new

 test "has correct service name" do
   assert_equal detector.service_name, "AWS VPC"
 end
 test "has correct resource type" do
   assert_equal detector.resource_type, "AWS::EC2::NatGateway"
 end
 test "generates default settings" do
   assert_equal detector.default_settings.count, 1
 end

  class IntegrationTests < BaseAwsIntegrationTest
    detector = UnusedNatGateways.new

    test "create resources" do
      scan = Scan.create(account: Account.first, credentials: Aws::SharedCredentials.new)
      before = Finding.count
      detector.execute(scan, "us-east-1")
      assert_equal before + 1, Finding.count
    end
  end
end
