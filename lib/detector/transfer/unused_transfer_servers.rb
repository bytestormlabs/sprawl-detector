require "aws-sdk-transfer"
require "date"
require "detector/support/cloudwatch"

class UnusedTransferServers
  ISSUE_TYPE = "aws-transfer-server-unused"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::Transfer::Client.new(region: region, credentials: scan.credentials)

    loop_until_finished(client, :list_servers) do |response|
      response.servers.each do |server|

        resource = scan.build_resource(region, resource_type, server.server_id, server)

        files_in =   check("AWS/Transfer", "FilesIn").with(scan.credentials).in(region).in_last(90).with_dimension("ServerId", server.server_id)
        files_out = check("AWS/Transfer", "FilesOut").with(scan.credentials).in(region).in_last(90).with_dimension("ServerId", server.server_id)

        resource.create_finding(ISSUE_TYPE) if files_in.indicates_zero_activity? && files_out.indicates_zero_activity?
      end
    end
  end

  def service_name
    "AWS Transfer Family"
  end

  def resource_type
    "AWS::Transfer::Server"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_file_activity", "The number of days (since today) to check for any incoming or outgoing file activity.", 90)
    ]
  end
end
