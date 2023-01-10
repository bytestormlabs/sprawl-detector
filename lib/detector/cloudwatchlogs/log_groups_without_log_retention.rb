require "detector/support/cloudwatch"
require "aws-sdk-cloudwatchlogs"

class LogGroupsWithoutLogRetention
  ISSUE_TYPE = "aws-logs-log-group-has-unacceptable-retention-period"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::CloudWatchLogs::Client.new(region: region, credentials: scan.credentials)
    loop_until_finished(client, :describe_log_groups) do |response|
      response.log_groups.each do |log_group|
        resource = scan.build_resource(region, resource_type, log_group.log_group_name, log_group)

        number_of_days = 30   # TODO: Refactor this

        resource.create_finding(ISSUE_TYPE) if
          log_group.retention_in_days.nil? ||
          log_group.retention_in_days > number_of_days
      end
    end
  end
  def service_name
    "AmazonCloudWatch"
  end

  def resource_type
    "AWS::Logs::LogGroup"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
