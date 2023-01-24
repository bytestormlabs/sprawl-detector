require "detector/support/cloudwatch"
require "aws-sdk-dynamodb"

# TODO: Rename this thing since its actually unused...not overprovisioned.
class OverProvisionedTables
  ISSUE_TYPE = "aws-dynamodb-unused-tables"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::DynamoDB::Client.new(region: region, credentials: scan.credentials)
    loop_until_finished(client, :list_tables) do |response|
      response.table_names.each do |table_name|
        table = client.describe_table(table_name: table_name).table

        resource = scan.build_resource(region, resource_type, table.table_name, table)
        number_of_days = 30   # TODO: Refactor this
        consumed_wcu = check("AWS/DynamoDB", "ConsumedWriteCapacityUnits")
          .in(region)
          .in_last(number_of_days)
          .with_dimension("TableName", table_name)
          .with(scan.credentials)

        consumed_rcu = check("AWS/DynamoDB", "ConsumedReadCapacityUnits")
          .in(region)
          .in_last(number_of_days)
          .with_dimension("TableName", table_name)
          .with(scan.credentials)

        resource.create_finding(scan, ISSUE_TYPE) if
          consumed_wcu.indicates_zero_activity? &&
            consumed_rcu.indicates_zero_activity?
      end
    end
  end

  def service_name
    "Amazon DynamoDB"
  end

  def resource_type
    "AWS::DynamoDB::Table"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
