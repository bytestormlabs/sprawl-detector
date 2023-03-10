require "detector/cache/unused_elasticache_clusters"
require "base_aws_integration_test"
require "test_helper"

class UnusedElastiCacheClustersTest < ActiveSupport::TestCase
  detector = UnusedElastiCacheClusters.new

  test "has correct service name" do
    assert detector.service_name == "Amazon ElastiCache"
  end
  test "has correct resource type" do
    assert detector.resource_type == "AWS::ElastiCache::CacheCluster"
  end
  test "generates default settings" do
    assert detector.default_settings.count == 1
  end

  class IntegrationTests < BaseAwsIntegrationTest
    detector = UnusedElastiCacheClusters.new
    fixtures(:accounts)

    test "handle has network activity" do
      scan = Scan.create(account: Account.first, credentials: Aws::Credentials.new("abc", "1234"))
      before = Resource.count
      detector.execute(scan, "us-east-1")
      after = Resource.count
      assert before < after
      assert Finding.where(issue_type: "aws-elasticache-instance-unused").count == 0
    end

    test "handle has no network activity" do
      scan = Scan.create(account: Account.first, credentials: Aws::Credentials.new("abc", "1234"))
      assert Finding.where(issue_type: "aws-elasticache-instance-unused").count == 0
      detector.execute(scan, "us-east-1")
      assert Finding.where(issue_type: "aws-elasticache-instance-unused").count == 1
    end
  end
end
