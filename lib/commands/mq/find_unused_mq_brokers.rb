require_relative "../command"
require "aws-sdk-mq"
# require "date"

class FindUnusedMqBrokers < Command
  def execute(context)
    each_region do |region|
      client = Aws::MQ::Client.new(region: region)

      brokers = client.list_brokers.broker_summaries

      brokers.each do |broker|
        if connection_count_check.matches(context, region, broker[:broker_name])
          create_finding(context, region, broker)
        end
      end
    end
  end

  def create_finding(context, region, broker)
    f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/mq").find_or_create_by(
      issue_type: connection_count_check.issue_type,
      resource_id: broker.broker_name,
      aws_account_id: context.aws_account_id, account: Account.find_by_account_id(context.aws_account_id)
    ).tap do |f|
      f.region = region
      f.message = connection_count_check.message,
        f.metadata = broker.to_h
      f.scan = context.scan
    end
    f.save!
  end

  def connection_count_check
    CloudWatchCheck.new({
      metric: "ConnectionCount",
      issue_type: "aws-mq-broker-instance-unused",
      statistic: "Average",
      attribute: "Broker",
      namespace: "AWS/AmazonMQ",
      period: (24 * 60 * 60),
      message: "No connections made in the time period."
    })
  end
end
