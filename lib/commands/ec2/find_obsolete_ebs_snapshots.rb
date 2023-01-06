require_relative "../command"
require "aws-sdk-ec2"
require "date"

class FindObsoluteEbsSnapshots < Command
  def execute(context)
    each_region do |region|
      ec2_client = Aws::EC2::Client.new(region: region)
      snapshots = ec2_client.describe_snapshots(owner_ids: [context.aws_account_id]).snapshots

      # TODO: Remove any in-use images
      snapshots.each do |snapshot|
        if snapshot.start_time < (DateTime.now - 120) # TODO: Refactor this into a parameter.
          f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/ec2").find_or_create_by(
            issue_type: "aws-ebs-snapshot-obsolete",
            resource_id: snapshot.snapshot_id,
            account_id: context.aws_account_id
          ).tap do |f|
            f.region = region
            f.message = "Amazon EBS snapshot is obsolete."
            f.metadata = snapshot.to_h
            f.scan = context.scan
          end
          f.save!
        end
      end
    end
  end
end
