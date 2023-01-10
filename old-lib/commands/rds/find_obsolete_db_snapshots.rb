require_relative "../command"
require "aws-sdk-rds"
require "date"

class FindObsoleteDbSnapshots < Command
  def execute(context)
    each_region do |region|
      rds_client = Aws::RDS::Client.new(region: region)
      db_cluster_snapshots = rds_client.describe_db_cluster_snapshots.db_cluster_snapshots

      # TODO: Remove any in-use images
      db_cluster_snapshots.each do |db_cluster_snapshot|
        if db_cluster_snapshot.snapshot_create_time < (DateTime.now - 120) # TODO: Refactor this into a parameter.
          f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/rds").find_or_create_by(
            issue_type: "aws-rds-db-snapshot-obsolete",
            resource_id: db_cluster_snapshot.db_cluster_snapshot_identifier,
            aws_account_id: context.aws_account_id, account: Account.find_by_account_id(context.aws_account_id)
          ).tap do |f|
            f.region = region
            f.message = "Amazon RDS database cluster snapshot is obsolete."
            f.metadata = db_cluster_snapshot.to_h
            f.scan = context.scan
          end
          f.save!
        end
      end
    end
  end
end
