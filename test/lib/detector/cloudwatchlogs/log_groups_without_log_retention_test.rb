require "detector/cloudwatchlogs/log_groups_without_log_retention"
require "base_aws_integration_test"
require "test_helper"

class LogGroupsWithoutLogRetentionTest < ActiveSupport::TestCase
  detector = LogGroupsWithoutLogRetention.new

  test "has correct service name" do
    assert detector.service_name == "AmazonCloudWatch"
  end
  test "has correct resource type" do
    assert detector.resource_type == "AWS::Logs::LogGroup"
  end
  test "generates default settings" do
    assert detector.default_settings.count == 1
  end

  class IntegrationTests < BaseAwsIntegrationTest
    detector = LogGroupsWithoutLogRetention.new
    fixtures(:accounts)

    test "create finding for log group with no retention" do
      scan = Scan.create(account: Account.first, credentials: Aws::Credentials.new("abc", "1234"))
      findings = Finding.count
      detector.execute(scan, "us-east-1")
      assert findings < Finding.count
    end
  end
end
