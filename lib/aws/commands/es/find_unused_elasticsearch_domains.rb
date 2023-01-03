require_relative "../command"
require "aws-sdk-elasticsearchservice"
require_relative "../../checks/cloudwatch/es_activity_check"

class FindUnusedElasticSearchDomains < Command
  def execute(context)
    each_region do |region|
      client = Aws::ElasticsearchService::Client.new(region: region)

      domain_names = client.list_domain_names.domain_names

      domain_names.each do |domain_name|
        if activity_check.matches(context, region, domain_name.domain_name)
          create_finding(context, region, domain_name)
        end
      end
    end
  end

  def create_finding(context, region, broker)
    f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/es").find_or_create_by(
      issue_type: activity_check.issue_type,
      resource_id: domain_name.domain_name,
      account_id: context.aws_account_id
    ).tap do |f|
      f.region = region
      f.message = activity_check.message,
      f.metadata = domain_name.to_h
      f.scan = context.scan
    end
    f.save!
  end

  def activity_check
    EsActivityCheck.new({
      metric: "2xx",
      issue_type: "aws-elastic-search-domain-unused",
      statistic: "Sum",
      attribute: "Broker",
      namespace: "AWS/ES",
      period: (24*60*60),
      message: "No activity during the time period."
    })
  end
end
