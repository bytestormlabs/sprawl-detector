require "aws-sdk-elasticache"
require "detector/support/cloudwatch"

class UnusedElastiCacheClusters
  ISSUE_TYPE = "aws-elasticache-instance-unused"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::ElastiCache::Client.new(region: region, credentials: scan.credentials)

    response = client.describe_cache_clusters
    response.cache_clusters.each do |cache_cluster|
      resource = scan.build_resource(region, resource_type, cache_cluster.cache_cluster_id, cache_cluster)
      number_of_days = 14   # TODO: Refactor this
      network_activity = check("AWS/ElastiCache", "NetworkBytesIn")
        .with(scan.credentials)
        .average
        .in(region)
        .in_last(number_of_days)
        .with_dimension("CacheClusterId", cache_cluster.cache_cluster_id)

        resource.create_finding(ISSUE_TYPE) if network_activity.less_than?(250000)
    end
  end

  def service_name
    "Amazon ElastiCache"
  end

  def resource_type
    "AWS::ElastiCache::CacheCluster"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
