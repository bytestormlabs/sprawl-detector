require "detector/support/cloudwatch"
require "aws-sdk-wafv2"

class UnusedWebAcls
  ISSUE_TYPE = "aws-wafv2-unused-web-acls"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::WAFV2::Client.new(region: region, credentials: scan.credentials)
    client.list_web_acls(scope: "REGIONAL").web_acls.each do |web_acl|
      resource = scan.build_resource(region, resource_type, web_acl.name, web_acl)

      number_of_days = 30   # TODO: Refactor this
      success = check("AWS/WAFV2", "CountedRequests")
        .in(region)
        .in_last(number_of_days)
        .with_dimension("WebACL", web_acl.name)
        .with_dimension("Region", region)
        .with_dimension("Rule", "ALL")
        .with(scan.credentials)

      resource.create_finding(scan, ISSUE_TYPE, success.last_activity_date) if success.indicates_zero_activity?
    end
  end

  def service_name
    "AWS WAF"
  end

  def resource_type
    "AWS::WAFv2::WebAcl"
  end

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this certificate authority issuing a certificate.", 90)
    ]
  end
end
