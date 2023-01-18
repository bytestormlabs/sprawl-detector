require "client/autoscaling_group_client"
require "base_aws_integration_test"

class AutoScalingGroupClientTest < BaseAwsIntegrationTest
  test "list resources with no filters" do
    client = AutoScalingGroupClient.new("us-east-2", Aws::SharedCredentials.new)
    resources = client.list_resources([])

    assert_equal 1, resources.count
  end

  test "list resources with a tag filter" do
    client = AutoScalingGroupClient.new("us-east-2", Aws::SharedCredentials.new)
    resources = client.list_resources([{name: "tag:Name", values: ["Staging ECS host"]}])

    assert_equal 1, resources.count
  end

  test "list resources with a tag filter that doesn't find anything" do
    client = AutoScalingGroupClient.new("us-east-2", Aws::SharedCredentials.new)
    resources = client.list_resources([{name: "tag:Name", values: ["OhioState!"]}])

    assert_equal 0, resources.count
  end

  test "stop the autoscaling group" do
    client = AutoScalingGroupClient.new("us-east-2", Aws::SharedCredentials.new)
    resources = client.list_resources([{name: "tag:Name", values: ["Staging ECS host"]}])
    resources.each do |resource|
      client.stop(resource)
      loop do
        break if client.is_stopped?(resource)
        sleep 0.001
      end
    end
  end
end
