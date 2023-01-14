require "detector/ec2/unused_client_vpn"
require "base_aws_integration_test"

class UnusedClientVpnTest < ActiveSupport::TestCase
  # detector = UnusedClientVpn.new

  #  test "has correct service name" do
  #    assert_equal detector.service_name, "AWS Service Name"
  #  end
  #  test "has correct resource type" do
  #    assert_equal detector.resource_type, "AWS::Service::ResourceType"
  #  end
  #  test "generates default settings" do
  #    assert_equal detector.default_settings.count, 1
  #  end

  # class IntegrationTests < BaseAwsIntegrationTest
  #   detector = UnusedClientVpn.new
  #
  #   test "create findings" do
  #     scan = Scan.create(account: Account.first, credentials: Aws::SharedCredentials.new)
  #     findings = Finding.count
  #     detector.execute(scan, "us-east-1")
  #     assert findings < Finding.count
  #   end
  # end
end
