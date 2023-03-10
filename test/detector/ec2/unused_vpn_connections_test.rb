require "detector/ec2/unused_vpn_connections"
require "base_aws_integration_test"

class UnusedVpnConnectionsTest < ActiveSupport::TestCase
  detector = UnusedVpnConnections.new

  test "has correct service name" do
    assert_equal "Amazon Virtual Private Cloud", detector.service_name
  end
  test "has correct resource type" do
    assert_equal "AWS::EC2::VPNConnection", detector.resource_type
  end
  test "generates default settings" do
    assert_equal detector.default_settings.count, 1
  end

  class IntegrationTests < BaseAwsIntegrationTest
    detector = UnusedVpnConnections.new

    test "create resources" do
      skip "need test resorces"
      scan = Scan.create(account: Account.first, credentials: Aws::SharedCredentials.new)
      findings = Finding.count
      detector.execute(scan, "us-east-1")
      assert findings < Finding.count
    end
  end
end
