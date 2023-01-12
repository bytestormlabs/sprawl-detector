require "detector/support/cloudwatch"
require "aws-sdk-mq"

class UnusedMqBrokers
  ISSUE_TYPE = "aws-mq-broker-instance-unused"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::MQ::Client.new(region: region, credentials: scan.credentials)
    response = client.list_brokers

    response.broker_summaries.each do |broker|
      resource = scan.build_resource(region, resource_type, broker.broker_name, broker)
      number_of_days = 14   # TODO: Refactor this

      connection_count = check("AWS/AmazonMQ", "ConnectionCount")
        .in(region)
        .in_last(number_of_days)
        .with_dimension("Broker", broker.broker_name)
        .with(scan.credentials)

      resource.create_finding(scan, ISSUE_TYPE) if broker.created < (DateTime.now - number_of_days) && connection_count.indicates_zero_activity?
    end
  end
  def service_name
    "Amazon MQ"
  end

  def resource_type
    "AWS::AmazonMQ::Broker"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
