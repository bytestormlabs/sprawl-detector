require "detector/support/cloudwatch"
require "aws-sdk-ec2"

class UnusedClientVpn
  ISSUE_TYPE = "aws-ec2-unused-client-vpn"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::EC2::Client.new(region: region, credentials: scan.credentials)
    loop_until_finished(client, :describe_client_vpn_endpoints) do |response|
      response.client_vpn_endpoints.each do |client_vpn_endpoint|
        resource = scan.build_resource(region, resource_type, client_vpn_endpoint.client_vpn_endpoint_id, client_vpn_endpoint)
        number_of_days = 30   # TODO: Refactor this
        active_connections = check("AWS/ClientVPN", "ActiveConnectionsCount")
          .in(region)
          .in_last(number_of_days)
          .with_dimension("Endpoint", client_vpn_endpoint.client_vpn_endpoint_id)
          .with(scan.credentials)

        resource.create_finding(scan, ISSUE_TYPE) if active_connections.indicates_zero_activity?
      end
    end
  end
  def service_name
    "Amazon Virtual Private Cloud"
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
