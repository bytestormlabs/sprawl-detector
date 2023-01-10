require "detector/support/cloudwatch"
require "aws-sdk-databasemigrationservice"
require "aws_sdk_operations"
require "assertions"

class UnusedReplicationInstances
  ISSUE_TYPE = "aws-dms-replication-instance-unused"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::DatabaseMigrationService::Client.new(region: region, credentials: scan.credentials)
    loop_until_finished(client, :describe_replication_instances) do |response|
      response.replication_instances.each do |replication_instance|
        resource = scan.build_resource(region, resource_type, replication_instance.replication_instance_identifier, replication_instance)
        number_of_days = 90   # TODO: Refactor this
        network_transmit_throughput = check("AWS/DMS", "NetworkTransmitThroughput")
          .in(region)
          .in_last(number_of_days)
          .with_dimension("ReplicationInstanceIdentifier", replication_instance.replication_instance_identifier)
          .with(scan.credentials)

        resource.create_finding(ISSUE_TYPE) if network_transmit_throughput.less_than?(20000)
      end
    end
  end

  def service_name
    "AWS Database Migration Service"
  end

  def resource_type
    "AWS::DMS::ReplicationInstance"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
