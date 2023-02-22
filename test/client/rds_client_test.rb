require "client/rds_clusters_client"
require "base_aws_integration_test"

class RdsClustersClientTest < BaseAwsIntegrationTest
  test "list resources with no filters" do
    client = RdsClustersClient.new("us-east-2", Aws::SharedCredentials.new)
    resources = client.list_resources([])

    assert_equal 1, resources.count
  end

  test "is_started?" do
    client = RdsClustersClient.new("us-east-2", Aws::SharedCredentials.new)
    is_started = client.is_started?({ db_cluster_identifier: "byte-storm-labs-staging-database-mysql-dbcluster-xh0cchxc4pg9"})

    assert_equal true, is_started
  end


  test "is_stopped?" do
    client = RdsClustersClient.new("us-east-2", Aws::SharedCredentials.new)
    is_stopped = client.is_stopped?({ db_cluster_identifier: "byte-storm-labs-staging-database-mysql-dbcluster-xh0cchxc4pg9"})

    assert_equal false, is_stopped
  end

  #
  # test "list resources with a tag filter that doesn't find anything" do
  #   client = AutoScalingGroupClient.new("us-east-2", Aws::SharedCredentials.new)
  #   resources = client.list_resources([{name: "tag:Name", values: ["OhioState!"]}])
  #
  #   assert_equal 0, resources.count
  # end
  #
  # test "stop the autoscaling group" do
  #   client = AutoScalingGroupClient.new("us-east-2", Aws::SharedCredentials.new)
  #   resources = client.list_resources([{name: "tag:Name", values: ["Staging ECS host"]}])
  #   resources.each do |resource|
  #     client.stop(resource)
  #     loop do
  #       break if client.is_stopped?(resource)
  #       sleep 0.001
  #     end
  #   end
  # end
end
