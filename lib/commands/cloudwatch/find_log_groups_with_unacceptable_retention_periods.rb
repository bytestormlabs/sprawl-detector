require_relative "../command"
require "aws-sdk-cloudwatchlogs"
require "date"

class FindLogGroupsWithUnacceptableRetentionPeriods < Command
  def execute(context)
    each_region do |region|
      logs_client = Aws::CloudWatchLogs::Client.new(region: region)
      params = {}

      loop do
        response = logs_client.describe_log_groups(params)
        log_groups = response.log_groups

        log_groups.each do |log_group|
          if log_group.retention_in_days.nil? || log_group.retention_in_days > 30 # TODO: Refactor as parameter
            f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/logs").find_or_create_by(
              issue_type: "aws-logs-log-group-has-unacceptable-retention-period",
              resource_id: log_group.log_group_name,
              account_id: context.aws_account_id
            ).tap do |f|
              f.region = region
              f.message = "Log group has an unacceptable retention period."
              f.metadata = log_group.to_h
              f.scan = context.scan
            end
            f.save!
          end
        end

        break if response.next_token.nil?
        params[:next_token] = response.next_token
      end
    end
  end
end
