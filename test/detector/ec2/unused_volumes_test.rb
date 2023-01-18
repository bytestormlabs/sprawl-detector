require "detector/ec2/unused_volumes"
require "base_aws_integration_test"

class UnusedVolumesTest < ActiveSupport::TestCase
  detector = UnusedVolumes.new

  test "has correct service name" do
    assert_equal detector.service_name, "EC2 - Other"
  end
  test "has correct resource type" do
    assert_equal detector.resource_type, "AWS::EC2::Volume"
  end
  test "generates default settings" do
    assert_equal detector.default_settings.count, 1
  end

  class IntegrationTests < BaseAwsIntegrationTest
    detector = UnusedVolumes.new

    test "create resources" do
      scan = Scan.create(account: Account.first, credentials: Aws::SharedCredentials.new)
      findings = Finding.count
      detector.execute(scan, "us-east-2")
      assert findings < Finding.count
    end
  end
end
