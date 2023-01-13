require "detector/databasemigrationservice/unused_replication_instances"
require "base_aws_integration_test"

class UnusedReplicationInstancesTest < ActiveSupport::TestCase
  detector = UnusedReplicationInstances.new

  test "has correct service name" do
    assert_equal detector.service_name, "AWS Database Migration Service"
  end
  test "has correct resource type" do
    assert_equal detector.resource_type, "AWS::DMS::ReplicationInstance"
  end
  test "generates default settings" do
    assert_equal detector.default_settings.count, 1
  end

  # class IntegrationTests < BaseAwsIntegrationTest
  #   detector = UnusedReplicationInstances.new
  #
  #   scan = Scan.create(account: Account.first, credentials: Aws::Credentials.new("abc", "1234"))
  #
  #   test "create resources" do
  #     findings = Finding.count
  #     detector.execute(scan, "us-east-1")
  #     assert findings < Finding.count
  #   end
  # end
end
