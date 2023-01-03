require_relative "../command"
require_relative "../../checks/cloudwatch/rds_cloudwatch_check"
require "aws-sdk-ec2"

class FindUnusedVolumes < Command
  def execute(context)
    each_region do |region|
      ec2_client = Aws::EC2::Client.new(region: region)
      volumes = ec2_client.describe_volumes.volumes

      volumes.each do |volume|
        if volume.state == "available"
          f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/ec2").find_or_create_by(
            issue_type: "aws-ec2-ebs-volume-unused",
            resource_id: volume.volume_id,
            account_id: context.aws_account_id
          ).tap do |f|
            f.region = region
            f.message = "EBS volume not attached to any EC2 instances."
            f.metadata = volume.to_h
            f.scan = context.scan
          end
          f.save!
        elsif is_attached_only_to_terminated_instances?(ec2_client, volume)
          f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/ec2").find_or_create_by(
            issue_type: "aws-ec2-ebs-volume-not-attached-to-running-instance",
            resource_id: volume.volume_id,
            account_id: context.aws_account_id
          ).tap do |f|
            f.region = region
            f.message = "EBS volume is attached to an EC2 instance that isn't running."
            f.metadata = volume.to_h
            f.scan = context.scan
          end
          f.save!
        end
      end
    end
  end

  def is_attached_only_to_terminated_instances?(ec2_client, volume)
    # make sure it's attached to a running Ec2 instance.
    instance_ids = volume.attachments.map(&:instance_id)
    reservations = ec2_client.describe_instances(instance_ids: instance_ids).reservations

    has_atleast_one_running_instance = reservations.map(&:instances).flatten.any? do |instance|
      instance.state.name == "running"
    end

    !has_atleast_one_running_instance
  end
end
