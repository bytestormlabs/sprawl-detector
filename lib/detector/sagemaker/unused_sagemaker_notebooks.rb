require "detector/support/cloudwatch"
require "aws-sdk-sagemaker"
require "aws-sdk-cloudwatchlogs"

class UnusedSagemakerNotebooks
  ISSUE_TYPE = "aws-sagemaker-notebook-instance-unused"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::SageMaker::Client.new(region: region, credentials: scan.credentials)
    logs_client = Aws::CloudWatchLogs::Client.new(region: region, credentials: scan.credentials)

    loop_until_finished(client, :list_notebook_instances, status_equals: "InService") do |response|
      response.notebook_instances.each do |notebook_instance|
        resource = scan.build_resource(region, resource_type, notebook_instance.notebook_instance_name, notebook_instance)

        number_of_days = 14   # TODO: Refactor this
        log_streams = logs_client.describe_log_streams(log_group_name: "/aws/sagemaker/NotebookInstances")&.log_streams

        last_log_stream = log_streams&.find do |log_stream|
          log_stream.log_stream_name == "#{notebook_instance.notebook_instance_name}/jupyter.log"
        end

        resource.create_finding(ISSUE_TYPE) if
          last_log_stream &&
          Time.at(last_log_stream.last_event_timestamp / 1000) < (DateTime.now - number_of_days)
      end
    end
  end
  def service_name
    "AWS SageMaker"
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
