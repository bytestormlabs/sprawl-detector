require "detector/ec2/obsolete_machine_images"
require "base_aws_integration_test"

class ObsoleteMachineImagesTest < ActiveSupport::TestCase
  # detector = ObsoleteMachineImages.new

  # test "has correct service name" do
  #   assert detector.service_name == "AWS Service Name"
  # end
  # test "has correct resource type" do
  #   assert detector.resource_type == "AWS::Service::ResourceType"
  # end
  # test "generates default settings" do
  #   assert detector.default_settings.count == 1
  # end

  class IntegrationTests < BaseAwsIntegrationTest
    detector = ObsoleteMachineImages.new
    fixtures(:accounts)

    test "create resources" do
      scan = Scan.create(account: Account.first, credentials: Aws::Credentials.new("abc", "1234"))
      findings = Finding.count
      detector.execute(scan, "us-east-1")
      assert findings < Finding.count
      assert Resource.where(resource_id: "ami-03ec7a88a2e498fce").first.findings.count == 1
    end
  end
end
