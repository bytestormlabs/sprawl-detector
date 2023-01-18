require "detector/dynamodb/over_provisioned_tables"
require "base_aws_integration_test"

class OverProvisionedTablesTest < ActiveSupport::TestCase
  detector = OverProvisionedTables.new

  test "has correct service name" do
    assert_equal detector.service_name, "Amazon DynamoDB"
  end
  test "has correct resource type" do
    assert_equal detector.resource_type, "AWS::DynamoDB::Table"
  end
  test "generates default settings" do
    assert_equal detector.default_settings.count, 1
  end

  class IntegrationTests < BaseAwsIntegrationTest
    detector = OverProvisionedTables.new

    test "create resources" do
      scan = Scan.create(account: Account.first, credentials: Aws::SharedCredentials.new)
      findings = Finding.count
      detector.execute(scan, "us-east-2")
      assert findings < Finding.count
    end
  end
end
