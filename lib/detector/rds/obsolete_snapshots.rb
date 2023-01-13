require "detector/support/cloudwatch"
require "aws-sdk-rds"

class ObsoleteSnapshots
  ISSUE_TYPE = "aws-rds-db-snapshot-obsolete"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::RDS::Client.new(region: region, credentials: scan.credentials)
    loop_until_finished(client, :describe_db_cluster_snapshots) do |response|
      response.db_cluster_snapshots.each do |db_cluster_snapshot|
        resource = scan.build_resource(region, resource_type, db_cluster_snapshot.db_cluster_snapshot_identifier, db_cluster_snapshot)
        number_of_days = 120   # TODO: Refactor this
        target_date = (DateTime.now - number_of_days)

        resource.create_finding(scan, ISSUE_TYPE) if db_cluster_snapshot.snapshot_create_time < target_date
      end
    end
  end
  def service_name
    "Amazon Relational Database Service"
  end

  def resource_type
    "AWS::RDS::ClusterSnapshot"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
