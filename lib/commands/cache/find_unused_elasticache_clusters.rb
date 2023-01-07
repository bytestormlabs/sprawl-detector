require_relative "../../checks/cloudwatch/cloudwatch_check"
require_relative "../command"
require "aws-sdk-elasticache"
require "date"

class FindUnusedElastiCacheClusters < Command
  def execute(context)
    each_region do |region|
      client = Aws::ElastiCache::Client.new(region: region)
      cache_clusters = client.describe_cache_clusters.cache_clusters

      cache_clusters.each do |cache_cluster|
        check_network_activity(context, region, cache_cluster)
      end
    end
  end

  def check_network_activity(context, region, cache_cluster)
    if network_bytes_out_check.matches(context, region, cache_cluster.cache_cluster_id)
      f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/elasticache").find_or_create_by(
        issue_type: network_bytes_out_check.issue_type,
        resource_id: cache_cluster.cache_cluster_id,
        aws_account_id: context.aws_account_id, account: Account.find_by_account_id(context.aws_account_id)
      ).tap do |f|
        f.region = region
        f.message = network_bytes_out_check.message
        f.metadata = cache_cluster.to_h
        f.scan = context.scan
      end
      f.save!
    end
  end

  def network_bytes_out_check
    CloudWatchCheck.new({
      metric: "NetworkBytesIn",
      issue_type: "aws-elasticache-instance-unused",
      statistic: "Average",
      attribute: "CacheClusterId",
      namespace: "AWS/ElastiCache",
      period: (24 * 60 * 60),
      message: "Extremely low network activity in the last week.",
      predicate: proc { |x| x < 200000 }
    })
  end
end
