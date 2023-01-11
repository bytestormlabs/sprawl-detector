require "detector/rds/unused_db_instances"
require "base_aws_integration_test"

class UnusedDbInstancesTest < ActiveSupport::TestCase
  detector = UnusedDbInstances.new

 test "has correct service name" do
   assert_equal detector.service_name, "AWS RDS"
 end
 test "has correct resource type" do
   assert_equal detector.resource_type, "AWS::RDS::DBInstance"
 end
 test "generates default settings" do
   assert_equal detector.default_settings.count, 1
 end

  class IntegrationTests < BaseAwsIntegrationTest
    detector = UnusedDbInstances.new

    test "create finding" do
      scan = Scan.create(account: Account.first, credentials: Aws::SharedCredentials.new)
      findings = Finding.count
      detector.execute(scan, "us-east-2")
      assert findings < Finding.count
    end
  end
end
