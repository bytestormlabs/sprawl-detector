require "detector/support/cloudwatch"
require "aws-sdk-ec2"

class UnusedInstances
  ISSUE_TYPE = "aws-ec2-instance-unused"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::EC2::Client.new(region: region, credentials: scan.credentials)
    loop_until_finished(client, :describe_instances, filters: [{name: "instance-state-name", values: ["running"]}]) do |response|
      response.reservations.each do |reservation|
        reservation.instances.each do |instance|
          resource = scan.build_resource(region, resource_type, instance.instance_id, instance)
          number_of_days = 14   # TODO: Refactor this
          network_in = check("AWS/EC2", "NetworkIn")
            .in(region)
            .in_last(number_of_days)
            .with_dimension("InstanceId", instance.instance_id)
            .with(scan.credentials)


          resource.create_finding(ISSUE_TYPE) if network_in.less_than?(600000)
        end
      end
    end
  end
  def service_name
    "AWS EC2"
  end

  def resource_type
    "AWS::EC2::Instance"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
