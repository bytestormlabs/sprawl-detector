require_relative "../../checks/cloudwatch/cloudwatch_check"
require_relative "../command"
require "aws-sdk-databasemigrationservice"
require "date"

class FindUnusedReplicationInstances < Command
  def execute(context)
    each_region do |region|
      client = Aws::DatabaseMigrationService::Client.new(region: region)
      replication_instances = client.describe_replication_instances.replication_instances

      replication_instances.each do |replication_instance|
        check_network_activity(context, region, replication_instance)
      end
    end
  end

  def check_network_activity(context, region, replication_instance)
    if network_bytes_out_check.matches(context, region, replication_instance.replication_instance_identifier)
      f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/dms").find_or_create_by(
        issue_type: network_bytes_out_check.issue_type,
        resource_id: replication_instance.replication_instance_identifier,
        account_id: context.aws_account_id
      ).tap do |f|
        f.region = region
        f.message = network_bytes_out_check.message
        f.metadata = replication_instance.to_h
        f.scan = context.scan
      end
      f.save!
    end
  end

  def network_bytes_out_check
    CloudWatchCheck.new({
      metric: "NetworkTransmitThroughput",
      issue_type: "aws-dms-replication-instance-unused",
      statistic: "Sum",
      attribute: "ReplicationInstanceIdentifier",
      namespace: "AWS/DMS",
      period: (24 * 60 * 60),
      message: "Extremely low network activity in the last week.",
      predicate: proc { |x| x < 20000 }
    })
  end
end
