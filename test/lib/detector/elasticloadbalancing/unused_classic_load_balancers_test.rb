require "detector/elasticloadbalancing/unused_classic_load_balancers"
require "base_aws_integration_test"

class UnusedClassicLoadBalancersTest < ActiveSupport::TestCase
  detector = UnusedClassicLoadBalancers.new

   test "has correct service name" do
     assert_equal detector.service_name, "Amazon Elastic Load Balancing"
   end
   test "has correct resource type" do
     assert_equal detector.resource_type, "AWS::ElasticLoadBalancing::LoadBalancer"
   end
   test "generates default settings" do
     assert_equal detector.default_settings.count, 1
   end

  class IntegrationTests < BaseAwsIntegrationTest
    detector = UnusedClassicLoadBalancers.new

    test "create resources" do
      scan = Scan.create(account: Account.first, credentials: Aws::SharedCredentials.new)
      findings = Finding.count
      detector.execute(scan, "us-east-1")
      assert findings < Finding.count
    end
  end
end
