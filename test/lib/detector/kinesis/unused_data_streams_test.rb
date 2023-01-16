require "detector/kinesis/unused_data_streams"
require "base_aws_integration_test"

class UnusedDataStreamsTest < ActiveSupport::TestCase
  detector = UnusedDataStreams.new

  test "has correct service name" do
    assert_equal detector.service_name, "Kinesis"
  end
  test "has correct resource type" do
    assert_equal detector.resource_type, "AWS::Kinesis::Stream"
  end
  test "generates default settings" do
    assert_equal detector.default_settings.count, 1
  end

  class IntegrationTests < BaseAwsIntegrationTest
    detector = UnusedDataStreams.new

    test "create resources" do
      scan = Scan.create(account: Account.first, credentials: Aws::SharedCredentials.new)
      findings = Finding.count
      detector.execute(scan, "us-east-1")
      assert findings + 8 == Finding.count
    end
  end
end
