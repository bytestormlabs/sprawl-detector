require "aws-sdk-cloudwatchlogs"
require "aws-sdk-sagemaker"
require_relative "../command"
require "date"

class FindUnusedSagemakerNotebooks < Command
  def execute(context)
    context.logger.debug "entering execute"

    each_region do |region|
      sm_client = Aws::SageMaker::Client.new(region: region)
      cwl_client = Aws::CloudWatchLogs::Client.new(region: region)

      notebook_instances = sm_client.list_notebook_instances(status_equals: "InService").notebook_instances

      context.logger.debug "Found #{notebook_instances&.size} running Jupyter notebook instances in #{region}."

      if notebook_instances&.size&.> 0
        # Find the last cloudwatch log event
        log_streams = cwl_client.describe_log_streams(log_group_name: "/aws/sagemaker/NotebookInstances")&.log_streams

        notebook_instances.each do |notebook_instance|
          # Detect the last event time in the log

          log_stream = log_streams&.find do |log_stream|
            log_stream.log_stream_name == "#{notebook_instance.notebook_instance_name}/jupyter.log"
          end

          if log_stream && Time.at(log_stream.last_event_timestamp / 1000).to_datetime < (DateTime.now - 7) # TODO: Refactor this into a configurable value
            f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/sagemaker").find_or_create_by(
              issue_type: "aws-sagemaker-notebook-instance-unused",
              resource_id: notebook_instance.notebook_instance_name,
              aws_account_id: context.aws_account_id, account: Account.find_by_account_id(context.aws_account_id)
            ).tap do |f|
              f.region = region
              f.message = "AWS Sagemaker notebook instance hasn't been used in 7 days."
              f.metadata = notebook_instance.to_h
              f.scan = context.scan
            end
            f.save!

          else
            context.logger.debug "AWS SageMaker notebook #{notebook_instance.notebook_instance_name} was last used at #{Time.at(log_stream.last_event_timestamp / 1000).to_datetime}"
            context.logger.debug "Current time is #{DateTime.now.utc}"
          end
        end
      end
    end
    context.logger.debug "exiting execute"
  end
end
