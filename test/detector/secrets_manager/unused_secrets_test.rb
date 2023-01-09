require "detector/secrets_manager/unused_secrets.rb"
require "base_aws_integration_test"

class UnusedSecretsTest < ActiveSupport::TestCase
  detector = UnusedSecrets.new

  test "has correct service name" do
    assert detector.service_name == "AWS Secrets Manager"
  end
  test "has correct resource type" do
    assert detector.resource_type == "AWS::SecretsManager::Secret"
  end
  test "generates default settings" do
    assert detector.default_settings.count == 1
  end

  class IntegrationTests < BaseAwsIntegrationTest
    detector = UnusedSecrets.new

    # TODO: Refactor this so it can be shared.
    scan = Scan.create(account: Account.first, credentials: Aws::SharedCredentials.new)

    test "handle no secrets found" do
      before = Resource.count
      detector.execute(scan, "us-east-1")
      after = Resource.count
      assert before == after, "No resources should have been created"
    end

    test "newly created secrets don't trigger findings" do
      before = Finding.count
      detector.execute(scan, "us-east-2")
      after = Finding.count
      assert before == after, "Newly created secrets shouldn't trigger findings"
    end

    test "resources are created" do
      before = Resource.count
      detector.execute(scan, "us-east-2")
      after = Resource.count
      assert (before + 2) == after, "Resources should be created during the scan"
    end

    test "obsolete secrets have findings" do
      before = Finding.count
      detector.execute(scan, "us-east-2")
      after = Finding.count
      assert (before + 2) == after, "Obsolete resources should have findings"
    end
  end
end
