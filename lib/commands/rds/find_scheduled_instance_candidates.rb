require "aws-sdk-rds"
require "aws-sdk-cloudwatch"
require_relative "../command"

class FindScheduledInstanceCandidates < Command
  def execute(context)
    each_region do |region|
      rds_client = Aws::RDS::Client.new(region: region)
      db_instances = rds_client.describe_db_instances[:db_instances]

      instances = db_instances.find_all do |db_instance|
        # Must be available
        db_instance[:db_instance_status] == "available"
      end

      instances.each do |instance|
        context.logger.debug "Getting connection metrics for instance #{instance[:db_instance_identifier]}"
        metric_statistics = get_connection_metrics(region, instance[:db_instance_identifier])

        context.logger.debug "Resolved #{metric_statistics[:datapoints].length} data points."
        metric_statistics[:datapoints].sort_by { |d| d[:timestamp] }.each do |m|
          context.logger.debug " timestamp: #{m[:timestamp]}, value: #{m[:minimum]}"
        end

        result = metric_statistics[:datapoints].group_by do |datapoint|
          datapoint[:timestamp].hour
        end.map do |hour, datapoints|
          # Calculate average
          {
            hour: hour,
            average_connections: (1.0 * datapoints.map { |d| d[:minimum] }.sum / datapoints.length)
          }
        end.sort_by { |i| i[:hour] }

        # Check if the value was 0 for all of these
        # periods_with_zero_connections = metric_statistics[:datapoints].count do |datapoint|
        #   datapoint[:maximum] < 1
        # end
        #
        # should_issue_finding = (periods_with_zero_connections == metric_statistics[:datapoints].length)
        #
        # if should_issue_finding
        #   context.logger.info "Creating a new finding for database instance #{instance[:db_instance_identifier]}"
        #   Finding.find_or_create_by(aws_account_id: context.aws_account_id, account: Account.find_by_account_id(context.aws_account_id), resource_id: instance[:db_instance_identifier], category: "aws/rds").tap do |f|
        #     f.finding_type = "unused_rds_instance"
        #     f.region = region
        #     f.status = Status.find_by_name("Open")
        #     f.save!
        #   end
        # end
      end
    end
  end

  private

  def get_connection_metrics(region, db_instance_identifier)
    client = Aws::CloudWatch::Client.new(region: region)
    client.get_metric_statistics(
      metric_name: "DatabaseConnections",
      namespace: "AWS/RDS",
      statistics: ["Minimum"],
      start_time: (DateTime.now - 14).to_s,
      end_time: DateTime.now.to_s,
      period: (60 * 60), # hourly
      dimensions: [
        {
          name: "DBInstanceIdentifier",
          value: db_instance_identifier
        }
      ]
    )
  end
end
