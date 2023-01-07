require_relative "../command"
require "aws-sdk-ec2"
require "date"

class FindObsoleteKeyPairs < Command
  def execute(context)
    each_region do |region|
      ec2_client = Aws::EC2::Client.new(region: region)
      keypairs = ec2_client.describe_key_pairs.key_pairs

      key_pairs_in_use = ec2_client.describe_instances.reservations.map do |reservation|
        reservation.instances.map do |instance|
          instance.key_name
        end
      end.flatten.compact.uniq

      puts "Found #{key_pairs_in_use}"

      # TODO: Remove any in-use images
      keypairs.each do |key_pair|
        unless key_pairs_in_use.include? key_pair.key_name
          f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/ec2").find_or_create_by(
            issue_type: "aws-ec2-keypair-obsolete",
            resource_id: key_pair.key_pair_id,
            aws_account_id: context.aws_account_id, account: Account.find_by_account_id(context.aws_account_id)
          ).tap do |f|
            f.region = region
            f.message = "Amazon EC2 Key Pair snapshot is obsolete."
            f.metadata = key_pair.to_h
            f.scan = context.scan
          end
          f.save!
        end
      end
    end
  end
end
