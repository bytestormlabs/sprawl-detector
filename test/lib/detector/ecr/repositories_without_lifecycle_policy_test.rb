require "detector/ecr/repositories_without_lifecycle_policy"
require "base_aws_integration_test"

class RepositoriesWithoutLifecyclePolicyTest < ActiveSupport::TestCase
  detector = RepositoriesWithoutLifecyclePolicy.new

  test "has correct service name" do
    assert_equal detector.service_name, "Amazon EC2 Container Registry (ECR)"
  end
  test "has correct resource type" do
    assert_equal detector.resource_type, "AWS::ECR::Repository"
  end
  test "generates default settings" do
    assert_equal detector.default_settings.count, 0
  end

  class IntegrationTests < BaseAwsIntegrationTest
    detector = RepositoriesWithoutLifecyclePolicy.new

    test "create create finding" do
      scan = Scan.create(account: Account.first, credentials: Aws::SharedCredentials.new)
      before = Finding.count
      detector.execute(scan, "us-east-2")
      assert_equal before + 2, Finding.count
    end
  end
end
