require "aws-sdk-ec2"

class ObsoleteKeyPairs
  ISSUE_TYPE = "aws-ec2-keypair-obsolete"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan,   "parameter 'scan' is required."

    client = Aws::EC2::Client.new(region: region, credentials: scan.credentials)
    key_pairs_in_use = []
    loop_until_finished(client, :describe_instances) do |response|
      response.reservations.each do |reservation|
        reservation.instances.each do |instance|
          key_pairs_in_use << instance.key_name
        end
      end
    end

    key_pairs_in_use.flatten.compact.uniq!

    client.describe_key_pairs.key_pairs.each do |key_pair|
      resource = scan.build_resource(region, resource_type, key_pair.key_name, key_pair)
      resource.create_finding(ISSUE_TYPE) unless key_pairs_in_use.include? key_pair.key_name
    end
  end
  def service_name
    "AWS EC2"
  end

  def resource_type
    "AWS::EC2::Keypair"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
