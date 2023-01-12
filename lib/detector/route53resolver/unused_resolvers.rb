require "detector/support/cloudwatch"
require "aws-sdk-route53resolver"

class UnusedResolvers
  ISSUE_TYPE = "aws-route53resolver-endpoint-unused"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::Route53Resolver::Client.new(region: region, credentials: scan.credentials)
    loop_until_finished(client, :list_resolver_endpoints) do |response|
      response.resolver_endpoints.each do |resolver_endpoint|
        resource = scan.build_resource(region, resource_type, resolver_endpoint.id, resolver_endpoint)

        number_of_days = 14   # TODO: Refactor this
        inbound_query = check("AWS/Route53Resolver", "InboundQueryVolume")
          .in(region)
          .in_last(number_of_days)
          .with_dimension("EndpointId", resolver_endpoint.id)
          .with(scan.credentials)

        outbound_query = check("AWS/Route53Resolver", "OutboundQueryVolume")
          .in(region)
          .in_last(number_of_days)
          .with_dimension("EndpointId", resolver_endpoint.id)
          .with(scan.credentials)

        resource.create_finding(scan, ISSUE_TYPE) if
          resolver_endpoint.creation_time < (DateTime.now - number_of_days) &&
          inbound_query.indicates_zero_activity? &&
          outbound_query.indicates_zero_activity?
      end
    end
  end
  def service_name
    "Amazon Route 53"
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
