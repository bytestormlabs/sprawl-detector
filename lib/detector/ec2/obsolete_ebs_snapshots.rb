require "detector/support/cloudwatch"
require "aws-sdk-ec2"

class ObsoleteEbsSnapshots
  ISSUE_TYPE = "aws-ebs-snapshot-obsolete"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::EC2::Client.new(region: region, credentials: scan.credentials)
    response = client.describe_snapshots(owner_ids: [scan.account.account_id])

    response.snapshots.each do |snapshot|
      resource = scan.build_resource(region, resource_type, snapshot.snapshot_id, snapshot)
      number_of_days = 120   # TODO: Refactor this

      resource.create_finding(ISSUE_TYPE) if snapshot.start_time < (DateTime.now - number_of_days)
    end
  end
  def service_name
    "EC2 - Other"
  end

  def resource_type
    "AWS::EBS::Volume"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
