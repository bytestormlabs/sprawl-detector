require_relative "../command"
require "aws-sdk-redshift"
require "date"

class FindObsoleteClusterSnapshots < Command
  def execute(context)
    each_region do |region|
      red_client = Aws::Redshift::Client.new(region: region)
      snapshots = red_client.describe_cluster_snapshots(snapshot_type: "manual").snapshots

      # TODO: Remove any in-use images
      snapshots.each do |snapshot|
        if snapshot.snapshot_create_time < (DateTime.now - 180) # TODO: Refactor this into a parameter.
          f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/redshift").find_or_create_by(
            issue_type: "aws-redshift-snapshot-obsolete",
            resource_id: snapshot.snapshot_identifier,
            aws_account_id: context.aws_account_id, account: Account.find_by_account_id(context.aws_account_id)
          ).tap do |f|
            f.region = region
            f.message = "Amazon Redshift DB Cluster snapshot is obsolete."
            f.metadata = snapshot.to_h
            f.scan = context.scan
          end
          f.save!
        end
      end
    end
  end
end
