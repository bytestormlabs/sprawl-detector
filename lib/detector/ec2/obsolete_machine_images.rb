require "detector/support/cloudwatch"
require "aws-sdk-ec2"

class ObsoleteMachineImages
  ISSUE_TYPE = "aws-ec2-ami-obsolete"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::EC2::Client.new(region: region, credentials: scan.credentials)

    image_ids_in_use = client.describe_instances.reservations.map do |reservation|
      reservation.instances.map do |instance|
        instance.image_id
      end
    end.flatten.compact.uniq

    images = client.describe_images(owners: [scan.account.account_id]).images

    images.each do |image|
      resource = scan.build_resource(region, resource_type, image.image_id, image)
      resource.create_finding(ISSUE_TYPE) if [
        !image_ids_in_use.include?(image.image_id),
        image.creation_date < (DateTime.now - 180)
      ].all?
    end
  end

  def service_name
    "EC2 - Other"
  end

  def resource_type
    "AWS::Service::ResourceType"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
