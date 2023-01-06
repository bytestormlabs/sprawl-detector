require_relative "../command"
require "aws-sdk-cloudwatchlogs"
require "date"

class FindObsoleteCloudwatchDashboard < Command
  def execute(context)
    each_region do |region|
      client = Aws::CloudWatch::Client.new(region: region)
      dashboards = client.list_dashboards.dashboard_entries

      # TODO: Remove any in-use images
      dashboards.each do |dashboard|
        if dashboard.last_modified < (DateTime.now - 180) # TODO: Refactor as parameter
          f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/cloudwatch").find_or_create_by(
            issue_type: "aws-cloudwatch-dashboard-obsolete",
            resource_id: dashboard.dashboard_name,
            account_id: context.aws_account_id
          ).tap do |f|
            f.region = region
            f.message = "Cloudwatch dashboard has not been modified within time period."
            f.metadata = dashboard.to_h
            f.scan = context.scan
          end
          f.save!
        end
      end
    end
  end
end
