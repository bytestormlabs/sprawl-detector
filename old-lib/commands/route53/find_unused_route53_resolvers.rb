require "aws-sdk-route53resolver"
require_relative "../command"

class FindUnusedRoute53Resolvers < Command
  def execute(context)
    context.logger.debug "entering execute"

    each_region do |region|
      client = Aws::Route53Resolver::Client.new(region: region)
      client.list_resolver_endpoints.resolver_endpoints.each do |resolver_endpoint|
        if check_query_activity(context, region, resolver_endpoint.id)
          f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/route53resolver").find_or_create_by(
            issue_type: "aws-route53resolver-endpoint-unused",
            resource_id: resolver_endpoint.id,
            aws_account_id: context.aws_account_id, account: Account.find_by_account_id(context.aws_account_id)
          ).tap do |f|
            f.region = region
            f.message = "No inbound or outbound DNS queries during the time period."
            f.metadata = resolver_endpoint.to_h
            f.scan = context.scan
          end
          f.save!
        end
      end
    end
    context.logger.debug "exiting execute"
  end

  private

  def check_query_activity(context, region, resolver_endpoint_id)
    inbound_query_check.matches(context, region, resolver_endpoint_id) && outbound_query_check.matches(context, region, resolver_endpoint_id)
  end

  def inbound_query_check
    CloudWatchCheck.new(
      metric: "InboundQueryVolume",
      namespace: "AWS/Route53Resolver",
      attribute: "EndpointId",
      statistic: "Sum",
      issue_type: "aws-transfer-server-unused",
      period: (60 * 60),
      message: "No file activity during the time period."
    )
  end

  def outbound_query_check
    CloudWatchCheck.new(
      metric: "InboundQueryVolume",
      namespace: "AWS/Route53Resolver",
      attribute: "EndpointId",
      statistic: "Sum",
      issue_type: "aws-transfer-server-unused",
      period: (60 * 60),
      message: "No file activity during the time period."
    )
  end
end
