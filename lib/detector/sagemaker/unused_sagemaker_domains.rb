require "detector/support/cloudwatch"
require "aws-sdk-sagemaker"
require "aws-sdk-cloudwatchlogs"

class UnusedSagemakerDomains
  ISSUE_TYPE = "aws-sagemaker-domain-instance-unused"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::SageMaker::Client.new(region: region, credentials: scan.credentials)
    logs_client = Aws::CloudWatchLogs::Client.new(region: region, credentials: scan.credentials)

    loop_until_finished(client, :list_domains) do |response|
      response.domains.each do |domain|
        resource = scan.build_resource(region, resource_type, domain.domain_id, domain)

        number_of_days = 14   # TODO: Refactor this
        log_streams = logs_client.describe_log_streams(log_group_name: "/aws/sagemaker/studio")&.log_streams

        last_activity_date = log_streams&.find_all do |log_stream|
          log_stream.log_stream_name.start_with?(domain.domain_id)
        end&.map do |log_stream|
          Time.at(log_stream.last_event_timestamp / 1000).to_datetime
        end&.max

        resource.create_finding(scan, ISSUE_TYPE) if last_activity_date && last_activity_date < (DateTime.now - number_of_days)
      end
    end
  end
  def service_name
    "Amazon SageMaker"
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
