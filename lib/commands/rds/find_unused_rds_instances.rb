require "aws-sdk-rds"
require_relative "../command"

class FindUnusedRdsInstances < Command
  def execute(context)
    each_region do |region|
      rds_client = Aws::RDS::Client.new(region: region)
      instances = rds_client.describe_db_instances.db_instances.find_all do |db_instance|
        # Must be available
        db_instance.db_instance_status == "available"
      end

      instances.each do |instance|
        db_instance_identifier = instance.db_instance_identifier

        # Execute the unused checks first...
        unused_rds_checks.each do |check|
          matches = check.matches(context, region, db_instance_identifier)

          context.logger.debug "checking #{check} #{matches}"
          if matches
            f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/rds").find_or_create_by(
              issue_type: check.issue_type,
              resource_id: db_instance_identifier,
              aws_account_id: context.aws_account_id, account: Account.find_by_account_id(context.aws_account_id)
            ).tap do |f|
              f.region = region
              f.message = check.message
              f.metadata = instance.to_h.slice(:db_instance_identifier, :db_instance_class, :engine, :instance_create_time, :multi_az, :engine_version, :db_cluster_identifier, :db_instance_arn, :tag_list)
              f.scan = context.scan
            end
            f.save!
          end
        end
      end
    end
  end

  private

  def unused_rds_checks
    [
      RdsCloudWatchCheck.new({
        metric: "DatabaseConnections",
        issue_type: "aws-rds-db-instance-unused",
        statistic: "Maximum",
        attribute: "DBInstanceIdentifier",
        period: (60 * 60 * 24),
        message: "No database connections have made in the last week."
      })
    ]
  end
end
