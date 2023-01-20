require "detector/support/cloudwatch"
require "aws-sdk-ec2"

class UnusedVpnConnections
  ISSUE_TYPE = "aws-vpc-unused-vpn-connections"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::EC2::Client.new(region: region, credentials: scan.credentials)
    loop_until_finished(client, :describe_vpn_connections) do |response|
      response.vpn_connections.each do |vpn_connection|
        resource = scan.build_resource(region, resource_type, vpn_connection.vpn_connection_id, vpn_connection)
        number_of_days = 30   # TODO: Refactor this
        data_in = check("AWS/VPN", "TunnelDataIn")
          .in(region)
          .in_last(number_of_days)
          .with_dimension("VpnId", vpn_connection.vpn_connection_id)
          .with(scan.credentials)

        data_out = check("AWS/VPN", "TunnelDataOut")
          .in(region)
          .in_last(number_of_days)
          .with_dimension("VpnId", vpn_connection.vpn_connection_id)
          .with(scan.credentials)

        resource.create_finding(scan, ISSUE_TYPE) if data_in.indicates_zero_activity? && data_out.indicates_zero_activity?
      end
    end
  end
  def service_name
    "Amazon Virtual Private Cloud"
  end

  def resource_type
    "AWS::EC2::VPNConnection"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
