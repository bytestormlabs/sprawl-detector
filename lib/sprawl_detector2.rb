require "aws-sdk-sts"

class SprawlDetector2
  attr_accessor :account, :role_session, :skip_update_costs

  def execute
    setup
    assume_role
    update_cost_and_usage_patterns
    find_detectors_by_cost_and_usage
    # report_findings
  end

  def setup
    @account = Account.find_by_account_id(ENV.fetch("AWS_ACCOUNT_ID"))
    @scan = Scan.create(account: @account, status: :started)
    @skip_update_costs = false
  end

  def find_detectors_by_cost_and_usage
    services_used = AwsCostLineItem.where(account: @account).last_30_days.group(:service, :region).sum(:cost)
    logger.info "Found #{services_used.count} services used in the last 30 days."

    services_used.each do |key, cost|
      (service, region) = key
      if cost > 0.01
        logger.info "Finding detector for '#{service}' which incurred #{"%.2f" % cost} of cost this period in #{region}."
      end
    end
  end

  def assume_role
    role_arn = "arn:aws:iam::#{ENV.fetch("AWS_ACCOUNT_ID")}:role/BS-SprawlDetector"
    role_session_name = "byte-storm-labs-sprawl-detector" # TODO: Refactor this

    logger.debug "Attempting to assume role as #{role_arn}"

    sts = Aws::STS::Client.new(region: "us-east-1")
    @role_session = sts.assume_role({
      external_id: @account.external_id,
      role_arn: role_arn,
      role_session_name: role_session_name
    })

    logger.debug "Starting role session as #{role_session_name}"
  end

  def update_cost_and_usage_patterns
    return if skip_update_costs
    client = Aws::CostExplorer::Client.new(credentials: @role_session)
    params = {
      time_period: {
        start: (DateTime.now - 60).strftime("%Y-%m-%d"),
        end: DateTime.now.strftime("%Y-%m-%d")
      },
      granularity: "DAILY",
      metrics: ["NetUnblendedCost"],
      group_by: [
        {
          type: "DIMENSION",
          key: "SERVICE"
        },
        {
          type: "DIMENSION",
          key: "REGION"
        }
      ]
    }

    # Collect all of the keys and then determine what we can do about it
    items = client.get_cost_and_usage(params).results_by_time.map do |result_by_time|
      result_by_time.groups.map do |group|
        (service, region) = group.keys
        cost = group.metrics.first.last.amount.to_f.round(2)

        AwsCostLineItem.create_with(cost: cost).find_or_create_by(
          account: @account,
          date: Date.parse(result_by_time.time_period.start),
          service: service,
          region: region
        ).save
      end
    end.flatten
    logger.debug "Stored cost & usage data for #{items.count} line items."
  end

  def logger
    @logger ||= Logger.new($stdout)
    @logger.level = Logger::DEBUG
    @logger.formatter = proc do |severity, datetime, progname, msg|
      date_format = datetime.strftime("%Y-%m-%d %H:%M:%S")
      "[#{date_format}] #{severity} [account_id: #{@account.account_id}]\t #{msg}\n"
    end
    @logger
  end
end
