require "detector/ec2/obsolete_key_pairs"
require "base_aws_integration_test"

class ObsoleteKeyPairsTest < ActiveSupport::TestCase
  detector = ObsoleteKeyPairs.new

  test "has correct service name" do
    assert detector.service_name == "AWS EC2"
  end
  
  test "has correct resource type" do
    assert detector.resource_type == "AWS::EC2::Keypair"
  end

  test "generates default settings" do
    assert detector.default_settings.count == 1
  end

  class IntegrationTests < BaseAwsIntegrationTest
    detector = ObsoleteKeyPairs.new

    scan = Scan.create(account: Account.first, credentials: Aws::SharedCredentials.new)

    test "create resources" do
      findings = Finding.count
      detector.execute(scan, "us-east-1")
      assert findings < Finding.count
    end
  end
end
