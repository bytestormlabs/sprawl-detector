require "detector/support/cloudwatch"
require "aws-sdk-ec2"

class UnusedVolumes
  ISSUE_TYPE = "aws-ec2-unused-volumes"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::EC2::Client.new(region: region, credentials: scan.credentials)
    loop_until_finished(client, :describe_volumes) do |response|
      response.volumes.each do |volume|
        resource = scan.build_resource(region, resource_type, volume.volume_id, volume)

        if volume.state == "available"
          resource.create_finding(scan, ISSUE_TYPE)
        elsif is_attached_only_to_terminated_instances?(client, volume)
          resource.create_finding(scan, ISSUE_TYPE)
        end
      end
    end
  end

  def is_attached_only_to_terminated_instances?(client, volume)
    # make sure it's attached to a running Ec2 instance.
    instance_ids = volume.attachments.map(&:instance_id)
    reservations = ec2_client.describe_instances(instance_ids: instance_ids).reservations

    has_atleast_one_running_instance = reservations.map(&:instances).flatten.any? do |instance|
      instance.state.name == "running"
    end

    !has_atleast_one_running_instance
  end

  def service_name
    "EC2 - Other"
  end

  def resource_type
    "AWS::EC2::Volume"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
