require "detector/transfer/unused_transfer_servers"
require "base_aws_integration_test"

class UnusedTransferServersTest < ActiveSupport::TestCase
  detector = UnusedTransferServers.new

  test "has correct service name" do
    assert detector.service_name == "AWS Transfer Family"
  end
  test "has correct resource type" do
    assert detector.resource_type == "AWS::Transfer::Server"
  end
  test "generates default settings" do
    assert detector.default_settings.count == 1
  end

  class IntegrationTests < BaseAwsIntegrationTest
    detector = UnusedTransferServers.new

    # TODO: Refactor this so it can be shared.
    scan = Scan.create(account: Account.first, credentials: Aws::Credentials.new("abc", "1234"))

    test "create findings" do
      findings = Finding.count
      detector.execute(scan, "us-east-1")
      assert findings < Finding.count
    end
  end
end
