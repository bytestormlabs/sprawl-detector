require "aws-sdk-cloudwatchlogs"
require "aws-sdk-sagemaker"
require_relative "../command"
require "date"

class FindUnusedSagemakerEndpoints < Command
  def execute(context)
    context.logger.debug "entering execute"

    each_region do |region|
      sm_client = Aws::SageMaker::Client.new(region: region)
      cwl_client = Aws::CloudWatchLogs::Client.new(region: region)

      domains = sm_client.list_domains.domains

      context.logger.debug "Found #{domains&.size} running SageMaker domains in #{region}."

      if domains&.size&.> 0
        # Find the last cloudwatch log event
        log_streams = cwl_client.describe_log_streams(log_group_name: "/aws/sagemaker/studio")&.log_streams

        domains.each do |domain|
          next if domain.status != "InService"

          # Find the Jupyter server log
          domain_log_streams = log_streams&.find_all do |log_stream|
            log_stream.log_stream_name.start_with?(domain.domain_id)
          end

          # Find the latest time

          last_touched = domain_log_streams&.map { |log_stream| Time.at(log_stream.last_event_timestamp / 1000).to_datetime }&.max

          puts "Last touched: #{last_touched}"
          if !last_touched.nil? && last_touched < (DateTime.now - 7) # TODO: Refactor this into a configurable value
            context.logger.debug "Creating a finding #{last_touched} < #{DateTime.now - 7}"
            f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/sagemaker").find_or_create_by(
              issue_type: "aws-sagemaker-domain-instance-unused",
              resource_id: domain.domain_id,
              aws_account_id: context.aws_account_id, account: Account.find_by_account_id(context.aws_account_id)
            ).tap do |f|
              f.region = region
              f.message = "AWS Sagemaker domain instance hasn't been used in 7 days."
              f.metadata = domain.to_h
              f.scan = context.scan
            end
            f.save!
          else
            context.logger.debug "AWS SageMaker domain #{domain.domain_id} was last used at #{last_touched}"
          end
        end
      end
    end
    context.logger.debug "exiting execute"
  end
end
