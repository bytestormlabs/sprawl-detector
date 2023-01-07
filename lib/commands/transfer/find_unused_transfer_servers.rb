require "aws-sdk-transfer"
require_relative "../command"

class FindUnusedTransferServers < Command
  def execute(context)
    context.logger.debug "entering execute"

    each_region do |region|
      client = Aws::Transfer::Client.new(region: region)
      client.list_servers.servers.each do |server|
        if check_file_activity(context, region, server.server_id)
          f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/transfer").find_or_create_by(
            issue_type: "aws-transfer-server-unused",
            resource_id: server.server_id,
            aws_account_id: context.aws_account_id, account: Account.find_by_account_id(context.aws_account_id)
          ).tap do |f|
            f.region = region
            f.message = "No file activity for AWS Transfer server in the last 90 days."
            f.metadata = server.to_h
            f.scan = context.scan
          end
          f.save!
        end
      end
    end
    context.logger.debug "exiting execute"
  end

  private

  def check_file_activity(context, region, server)
    files_in_check.matches(context, region, server) && files_out_check.matches(context, region, server)
  end

  def files_in_check
    CloudWatchCheck.new(
      metric: "FilesIn",
      namespace: "AWS/Transfer",
      attribute: "ServerId",
      issue_type: "aws-transfer-server-unused",
      period: (24 * 60 * 60),
      message: "No file activity during the time period.",
      start_time: (DateTime.now - 90)
    )
  end

  def files_out_check
    CloudWatchCheck.new(
      metric: "FilesOut",
      namespace: "AWS/Transfer",
      attribute: "ServerId",
      issue_type: "aws-transfer-server-unused",
      period: (24 * 60 * 60),
      message: "No file activity during the time period.",
      start_time: (DateTime.now - 90)
    )
  end
end
