require "detector/rds/obsolete_snapshots"
require "base_aws_integration_test"

class ObsoleteSnapshotsTest < ActiveSupport::TestCase
  detector = ObsoleteSnapshots.new

 test "has correct service name" do
   assert_equal detector.service_name, "AWS RDS"
 end
 test "has correct resource type" do
   assert_equal detector.resource_type, "AWS::RDS::ClusterSnapshot"
 end
 test "generates default settings" do
   assert_equal detector.default_settings.count, 1
 end

  class IntegrationTests < BaseAwsIntegrationTest
    detector = ObsoleteSnapshots.new

    test "create resources" do
      scan = Scan.create(account: Account.first, credentials: Aws::SharedCredentials.new)
      before = Finding.count
      detector.execute(scan, "us-east-2")
      assert_equal before + 6, Finding.count
    end
  end
end
