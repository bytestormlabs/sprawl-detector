require "aws-sdk-sts"
require "detector/acm/unused_private_acm_ca"
require "detector/cache/unused_elasticache_clusters"
require "detector/cloudwatch/obsolete_dashboards"
require "detector/cloudwatchlogs/log_groups_without_log_retention"
require "detector/databasemigrationservice/unused_replication_instances"
require "detector/ec2/obsolete_ebs_snapshots"
require "detector/ec2/obsolete_key_pairs"
require "detector/ec2/obsolete_machine_images"
require "detector/ec2/unused_instances"
require "detector/ec2/unused_nat_gateways"
require "detector/ec2/unused_security_groups"
require "detector/ecr/repositories_without_lifecycle_policy"
require "detector/elasticloadbalancingv2/unused_load_balancers"
require "detector/elasticsearchservice/unused_domains"
require "detector/mq/unused_mq_brokers"
require "detector/rds/obsolete_snapshots"
require "detector/rds/unused_db_instances"
require "detector/redshift/obsolete_cluster_snapshots"
require "detector/redshift/unused_redshift_cluster"
require "detector/route53resolver/unused_resolvers"
require "detector/sagemaker/unused_sagemaker_domains"
require "detector/sagemaker/unused_sagemaker_notebooks"
require "detector/secretsmanager/unused_secrets"
require "detector/support/cloudwatch"
require "detector/transfer/unused_transfer_servers"
require "detector/vpc/unused_vpc_endpoints"

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
    puts "Running scan# #{@scan.id}"
    @skip_update_costs = true
  end

  def find_detectors_by_cost_and_usage
    services_used = AwsCostLineItem.where(account: @account).last_30_days.group(:service, :region).sum(:cost)
    logger.info "Found #{services_used.count} services used in the last 30 days."

    services_used.each do |key, cost|
      (service, region) = key
      if cost > 0.01
        logger.info "Finding detector for '#{service}' which incurred #{"%.2f" % cost} of cost this period in #{region}."

        next if region == "global"

        instances = detectors.find_all do |d|
          d.service_name == service
        end

        logger.info "Found #{instances&.count} detectors..."

        instances.each do |detector|
          logger.info "Detecting #{detector}..."
          begin
            detector.execute(@scan, region)
          rescue RuntimeError => e
            logger.error "Unhandled exception from #{detector}"
            logger.error e
          end
        end unless instances.nil?
      end
    end

    logger.info "Found #{@scan.findings.count} findings."
    @scan.completed!
  end

  def assume_role
    if ENV["AWS_PROFILE"]
      logger.info "Skipping assume role and using AWS profile #{ENV["AWS_PROFILE"]}"
      @role_session = Aws::SharedCredentials.new
    else
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

    @scan.credentials = @role_session
  end

  def update_cost_and_usage_patterns
    return if skip_update_costs
    client = Aws::CostExplorer::Client.new(credentials: @role_session)
    params = {
      time_period: {
        start: (DateTime.now - 30).strftime("%Y-%m-%d"),
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
      "[#{severity}] [account_id: #{@account.account_id}]\t #{msg}\n"
    end
    @logger
  end

  def detectors
    [
      LogGroupsWithoutLogRetention.new,
      ObsoleteClusterSnapshots.new,
      ObsoleteDashboards.new,
      ObsoleteEbsSnapshots.new,
      ObsoleteKeyPairs.new,
      ObsoleteMachineImages.new,
      ObsoleteSnapshots.new,
      RepositoriesWithoutLifecyclePolicy.new,
      UnusedDbInstances.new,
      UnusedDomains.new,
      UnusedElastiCacheClusters.new,
      UnusedInstances.new,
      UnusedLoadBalancers.new,
      UnusedMqBrokers.new,
      UnusedNatGateways.new,
      UnusedPrivateAcmCA.new,
      UnusedRedshiftCluster.new,
      UnusedReplicationInstances.new,
      UnusedResolvers.new,
      UnusedSagemakerDomains.new,
      UnusedSagemakerNotebooks.new,
      UnusedSecrets.new,
      UnusedSecurityGroups.new,
      UnusedTransferServers.new,
      UnusedVpcEndpoints.new
    ]
  end
end
