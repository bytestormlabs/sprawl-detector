require "detector/support/cloudwatch"
require "aws-sdk-elasticsearchservice"

class UnusedDomains
  ISSUE_TYPE = "aws-elastic-search-domain-unused"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::ElasticsearchService::Client.new(region: region, credentials: scan.credentials)
    loop_until_finished(client, :list_domain_names) do |response|
      response.domain_names.each do |domain_name|
        resource = scan.build_resource(region, resource_type, domain_name.domain_name, domain_name)
        number_of_days = 14   # TODO: Refactor this
        success = check("AWS/ES", "2xx")
          .in(region)
          .in_last(number_of_days)
          .with_dimension("DomainName", domain_name.domain_name)
          .with_dimension("ClientId", scan.account.account_id)
          .with(scan.credentials)

        searchable_documents = check("AWS/ES", "SearchableDocuments")
          .in(region)
          .in_last(number_of_days)
          .with_dimension("DomainName", domain_name.domain_name)
          .with_dimension("ClientId", scan.account.account_id)
          .with(scan.credentials)

        resource.create_finding(scan, ISSUE_TYPE) if [
          success.indicates_zero_activity?,
          searchable_documents.indicates_zero_activity?
        ].any?
      end
    end
  end

  def service_name
    "Amazon OpenSearch Service"
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
