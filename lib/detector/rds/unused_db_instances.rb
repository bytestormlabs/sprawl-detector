require "detector/support/cloudwatch"
require "aws-sdk-rds"

class UnusedDbInstances
  ISSUE_TYPE = "aws-rds-db-instance-unused"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::RDS::Client.new(region: region, credentials: scan.credentials)
    loop_until_finished(client, :describe_db_instances) do |response|
      response.db_instances.each do |db_instance|
        resource = scan.build_resource(region, resource_type, db_instance.db_instance_identifier, db_instance)
        # next if db_instance.db_instance_status != "available"

        number_of_days = 14   # TODO: Refactor this
        success = check("AWS/RDS", "DatabaseConnections")
          .in(region)
          .in_last(number_of_days)
          .with_dimension("DBInstanceIdentifier", db_instance.db_instance_identifier)
          .with(scan.credentials)

        resource.create_finding(ISSUE_TYPE) if db_instance.instance_create_time < (DateTime.now - number_of_days) && success.indicates_zero_activity?
      end
    end
  end
  def service_name
    "AWS RDS"
  end

  def resource_type
    "AWS::RDS::DBInstance"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
