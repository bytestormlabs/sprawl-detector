require "detector/ec2/unused_security_groups"
require "base_aws_integration_test"

class UnusedSecurityGroupsTest < ActiveSupport::TestCase
  detector = UnusedSecurityGroups.new

 test "has correct service name" do
   assert_equal detector.service_name, "Amazon Elastic Compute Cloud - Compute"
 end
 test "has correct resource type" do
   assert_equal detector.resource_type, "AWS::EC2::SecurityGroup"
 end
 test "generates default settings" do
   assert_equal detector.default_settings.count, 0
 end

  class IntegrationTests < BaseAwsIntegrationTest
    detector = UnusedSecurityGroups.new

    test "create resources" do
      scan = Scan.create(account: Account.first, credentials: Aws::Credentials.new("abc", "123"))
      findings = Finding.count
      detector.execute(scan, "us-east-1")
      assert findings < Finding.count
    end
  end
end
