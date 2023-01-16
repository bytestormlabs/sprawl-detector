require "detector/support/cloudwatch"
require "aws-sdk-kinesis"

class UnusedDataStreams
  ISSUE_TYPE = "aws-kinesis-unused-data-stream"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::Kinesis::Client.new(region: region, credentials: scan.credentials)
    loop_until_finished(client, :list_streams) do |response|
      response.stream_summaries.each do |stream|
        resource = scan.build_resource(region, resource_type, stream.stream_name, stream)
        number_of_days = 30   # TODO: Refactor this
        records_processed = check("AWS/Kinesis", "GetRecords.Records")
          .in(region)
          .in_last(number_of_days)
          .with_dimension("StreamName", stream.stream_name)
          .with(scan.credentials)

        resource.create_finding(scan, ISSUE_TYPE) if
          Time.at(stream.stream_creation_timestamp) < (DateTime.now - number_of_days) &&
            records_processed.indicates_zero_activity?
      end
    end
  end

  def service_name
    "Kinesis"
  end

  def resource_type
    "AWS::Kinesis::Stream"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
