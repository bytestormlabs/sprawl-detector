require "detector/ec2/unused_instances"
require "base_aws_integration_test"

class UnusedInstancesTest < ActiveSupport::TestCase
  detector = UnusedInstances.new

 test "has correct service name" do
   assert_equal detector.service_name, "AWS EC2"
 end
 test "has correct resource type" do
   assert_equal detector.resource_type, "AWS::EC2::Instance"
 end
 test "generates default settings" do
   assert_equal detector.default_settings.count, 1
 end

  # class IntegrationTests < BaseAwsIntegrationTest
  #   detector = UnusedInstances.new
  #
  #   test "create resources" do
  #     scan = Scan.create(account: Account.first, credentials: Aws::SharedCredentials.new)
  #     findings = Finding.count
  #     detector.execute(scan, "us-east-1")
  #     assert findings < Finding.count
  #   end
  # end
end
