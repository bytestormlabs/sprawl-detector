require "aws-sdk-rds"

class RdsClustersClient
  attr_accessor :client

  def initialize(region, credentials)
    @client = Aws::RDS::Client.new(region: region, credentials: credentials)
  end

  def list_resources(filters)
    client.describe_db_clusters(filters: filters).db_clusters
  end

  def describe(resource)
    client.describe_db_clusters(db_cluster_identifier: resource[:db_cluster_identifier]).db_clusters.first
  end

  def start(resource)
    # Find the autoscaling group by name and update the desired capacity to match
    params = resource.to_h.slice(:db_cluster_identifier)
    client.start_db_cluster(params)
  end

  def is_started?(resource)
    describe(resource).status == "available"
  end

  def stop(resource)
    params = resource.to_h.slice(:db_cluster_identifier)
    client.stop_db_cluster(params)
  end

  def is_stopped?(resource)
    describe(resource).status == "stopped"
  end
end
