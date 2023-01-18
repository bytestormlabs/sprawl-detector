require "detector/elasticloadbalancingv2/unused_load_balancers"
require "base_aws_integration_test"

class UnusedLoadBalancersTest < ActiveSupport::TestCase
  def detector
    UnusedLoadBalancers.new
  end

  test "has correct service name" do
    assert_equal detector.service_name, "Amazon Elastic Load Balancing"
  end

  test "generates default settings" do
    assert_equal detector.default_settings.count, 1
  end

  class IntegrationTests < BaseAwsIntegrationTest
    test "create create finding for unused load balancer" do
      scan = Scan.create(account: Account.first, credentials: Aws::SharedCredentials.new)
      findings = Finding.count
      UnusedLoadBalancers.new.execute(scan, "us-east-2")
      assert findings < Finding.count
    end
  end
end
