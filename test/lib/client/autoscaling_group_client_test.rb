require "client/autoscaling_group_client"
require "base_aws_integration_test"

class AutoScalingGroupClientTest < BaseAwsIntegrationTest
  test "list resources with no filters" do
    client = AutoScalingGroupClient.new("us-east-2", Aws::SharedCredentials.new)
    resources = client.list_resources([])

    assert_equal 1, resources.count
  end
end
