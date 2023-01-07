require "aws-sdk-ec2"
require_relative "../command"

class FindUnusedInstances < Command
  def execute(context)
    context.logger.debug "entering execute"

    each_region do |region|
      ec2_client = Aws::EC2::Client.new(region: region)
      ec2_client.describe_instances(filters: [{name: "instance-state-name", values: ["running"]}]).reservations.each do |reservation|
        reservation.instances.each do |instance|
          checks.each do |check|
            matches = check.matches(context, region, instance.instance_id)
            if matches
              f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/ec2").find_or_create_by(
                issue_type: check.issue_type,
                resource_id: instance.instance_id,
                aws_account_id: context.aws_account_id, account: Account.find_by_account_id(context.aws_account_id)
              ).tap do |f|
                f.region = region
                f.message = check.message
                f.metadata = instance.to_h.slice(:image_id, :instance_id, :instance_type, :launch_time, :placement, :private_dns_name, :private_ip_address, :public_dns_name, :public_ip_address, :subnet_id, :vpc_id, :tags)
                f.scan = context.scan
              end
              f.save!
            end
          end
        end
      end
    end
    context.logger.debug "exiting execute"
  end

  private

  def checks
    [
      Ec2CloudWatchCheck.new({
        metric: "NetworkIn",
        issue_type: "aws-ec2-instance-unused",
        statistic: "Average",
        attribute: "InstanceId",
        message: "Extremely low network activity in the time period.",
        predicate: proc { |x| x < 25000 }
      })
    ]
  end
end
