require "detector/support/cloudwatch"
require "aws-sdk-redshift"

class UnusedRedshiftCluster
  ISSUE_TYPE = "aws-redshift-unused-cluster"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::Redshift::Client.new(region: region, credentials: scan.credentials)
    client.describe_clusters.clusters.each do |cluster|
      resource = scan.build_resource(region, resource_type, cluster.cluster_identifier, cluster)
      next if cluster.cluster_status != "available"

      number_of_days = 14
      database_connections = check("AWS/Redshift", "DatabaseConnections")
        .in(region)
        .in_last(number_of_days)
        .with_dimension("ClusterIdentifier", cluster.cluster_identifier)
        .with(scan.credentials)

      resource.create_finding(scan, ISSUE_TYPE) if database_connections.indicates_zero_activity? && cluster.cluster_create_time < (DateTime.now - number_of_days)
    end
  end

  def service_name
    "Amazon Redshift"
  end

  def resource_type
    "AWS::Redshift::Cluster"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
