require "detector/cloudwatch/obsolete_dashboards"
require "base_aws_integration_test"
require "test_helper"

class ObsoleteDashboardsTest < ActiveSupport::TestCase
  detector = ObsoleteDashboards.new

  test "has correct service name" do
    assert detector.service_name == "AmazonCloudWatch"
  end
  test "has correct resource type" do
    assert detector.resource_type == "AWS::CloudWatch::Dashboard"
  end
  test "generates default settings" do
    assert detector.default_settings.count == 1
  end

  class IntegrationTests < BaseAwsIntegrationTest
    detector = ObsoleteDashboards.new

    scan = Scan.create(account: Account.first, credentials: Aws::SharedCredentials.new)

    test "create resources" do
      detector.execute(scan, "us-east-1")
      findings = Resource.where(resource_id: "Super_Neat_Dashboard01").first.findings
      assert_equal findings.count, 1
      assert_equal "aws-cloudwatch-dashboard-obsolete", findings.first.issue_type
    end
  end
end
