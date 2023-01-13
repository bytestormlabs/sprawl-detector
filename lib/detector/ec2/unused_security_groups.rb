require "detector/support/cloudwatch"
require "aws-sdk-ec2"

class UnusedSecurityGroups
  ISSUE_TYPE = "aws-ec2-unused-security-groups"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::EC2::Client.new(region: region, credentials: scan.credentials)
    security_groups = []
    network_interfaces = []

    loop_until_finished(client, :describe_network_interfaces) do |response|
      network_interfaces << response.network_interfaces
    end
    loop_until_finished(client, :describe_security_groups) do |response|
      security_groups << response.security_groups
    end

    security_groups.flatten!
    network_interfaces.flatten.each do |network_interface|
      network_interface.groups&.each do |group|
        security_groups.reject! do |sg|
          sg.group_id == group.group_id
        end
      end
    end

    security_groups.each do |security_group|
      resource = scan.build_resource(region, resource_type, security_group.group_name, security_group)
      resource.create_finding(scan, ISSUE_TYPE)
    end
  end

  def service_name
    "Amazon Elastic Compute Cloud - Compute"
  end

  def resource_type
    "AWS::EC2::SecurityGroup"
  end

  def default_settings
    []
  end
end
