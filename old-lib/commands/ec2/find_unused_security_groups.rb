require_relative "../command"
require "aws-sdk-ec2"

class FindUnusedSecurityGroups < Command
  def execute(context)
    each_region do |region|
      ec2_client = Aws::EC2::Client.new(region: region)
      security_groups = ec2_client.describe_security_groups.security_groups

      # Find all in-use security groups for EC2 instances
      context.logger.debug "Starting list with #{security_groups.length} security groups."

      ec2_client.describe_network_interfaces.network_interfaces.each do |network_interface|
        network_interface.groups&.each do |group|
          security_groups.reject! do |sg|
            sg.group_id == group.group_id
          end
        end
      end

      context.logger.debug "Ending with #{security_groups.length} security groups."

      security_groups.each do |security_group|
        f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/ec2").find_or_create_by(
          issue_type: "aws-ec2-security-group-unused",
          resource_id: security_group.group_id,
          aws_account_id: context.aws_account_id, account: Account.find_by_account_id(context.aws_account_id)
        ).tap do |f|
          f.region = region
          f.message = "Security group not attached to any network interfaces."
          f.metadata = security_group.to_h
          f.scan = context.scan
        end
        f.save!
      end
    end
  end
end
