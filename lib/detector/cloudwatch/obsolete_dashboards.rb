require "detector/support/cloudwatch"
require "aws-sdk-cloudwatch"

class ObsoleteDashboards
  ISSUE_TYPE = "aws-cloudwatch-dashboard-obsolete"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::CloudWatch::Client.new(region: region, credentials: scan.credentials)
    loop_until_finished(client, :list_dashboards) do |response|
      response.dashboard_entries.each do |dashboard|
        resource = scan.build_resource(region, resource_type, dashboard.dashboard_name, dashboard)
        number_of_days = 180   # TODO: Refactor this

        resource.create_finding(scan, ISSUE_TYPE) if dashboard.last_modified < (DateTime.now - number_of_days)
      end
    end
  end

  def service_name
    "AmazonCloudWatch"
  end

  def resource_type
    "AWS::CloudWatch::Dashboard"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
