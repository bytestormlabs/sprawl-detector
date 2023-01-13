require "detector/support/cloudwatch"
require "aws-sdk-redshift"

class ObsoleteClusterSnapshots
  ISSUE_TYPE = "aws-redshift-snapshot-obsolete"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::Redshift::Client.new(region: region, credentials: scan.credentials)
    loop_until_finished(client, :describe_cluster_snapshots, snapshot_type: "manual") do |response|
      response.snapshots.each do |snapshot|
        resource = scan.build_resource(region, resource_type, snapshot.snapshot_identifier, snapshot)
        number_of_days = 90   # TODO: Refactor this

        resource.create_finding(scan, ISSUE_TYPE) if snapshot.snapshot_create_time < (DateTime.now - number_of_days)
      end
    end
  end

  def service_name
    "AWS Redshift"
  end

  def resource_type
    "AWS::Service::ResourceType"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
