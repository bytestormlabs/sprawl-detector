require "detector/directoryservice/unused_directories"
require "base_aws_integration_test"

class UnusedDirectoriesTest < ActiveSupport::TestCase
  detector = UnusedDirectories.new

  test "has correct service name" do
    assert_equal detector.service_name, "AWS Directory Service"
  end
  test "has correct resource type" do
    assert_equal detector.resource_type, "AWS::DirectoryService::MicrosoftAD"
  end
  test "generates default settings" do
    assert_equal detector.default_settings.count, 1
  end

  # class IntegrationTests < BaseAwsIntegrationTest
  #   detector = UnusedDirectories.new
  #
  #   test "create resources" do
  #     scan = Scan.create(account: Account.first, credentials: Aws::SharedCredentials.new)
  #     findings = Finding.count
  #     detector.execute(scan, "us-east-1")
  #     assert findings < Finding.count
  #   end
  # end
end
