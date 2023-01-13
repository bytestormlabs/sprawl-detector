require "detector/lambda/unused_lambda_functions"
require "base_aws_integration_test"

class UnusedLambdaFunctionsTest < ActiveSupport::TestCase
  detector = UnusedLambdaFunctions.new

 test "has correct service name" do
   assert_equal detector.service_name, "AWS Lambda"
 end
 test "has correct resource type" do
   assert_equal detector.resource_type, "AWS::Lambda::Function"
 end
 test "generates default settings" do
   assert_equal detector.default_settings.count, 1
 end

  class IntegrationTests < BaseAwsIntegrationTest
    # detector = UnusedLambdaFunctions.new

    # test "create finding" do
    #   scan = Scan.create(account: Account.first, credentials: Aws::SharedCredentials.new)
    #   findings = Finding.count
    #   detector.execute(scan, "us-east-1")
    #   assert findings < Finding.count
    # end
  end
end
