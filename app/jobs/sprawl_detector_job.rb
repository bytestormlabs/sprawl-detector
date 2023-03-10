require "aws-sdk-sts"
require "detector/acm/unused_private_acm_ca"
require "detector/cache/unused_elasticache_clusters"
require "detector/cloudwatch/obsolete_dashboards"
require "detector/cloudwatchlogs/log_groups_without_log_retention"
require "detector/databasemigrationservice/unused_replication_instances"
require "detector/directoryservice/unused_directories"
require "detector/dynamodb/over_provisioned_tables"
require "detector/ec2/obsolete_ebs_snapshots"
require "detector/ec2/obsolete_key_pairs"
require "detector/ec2/obsolete_machine_images"
require "detector/ec2/unused_client_vpn"
require "detector/ec2/unused_instances"
require "detector/ec2/unused_nat_gateways"
require "detector/ec2/unused_security_groups"
require "detector/ec2/unused_volumes"
require "detector/ec2/unused_vpn_connections"
require "detector/ec2/vpc_without_s3_endpoint"
require "detector/ecr/repositories_without_lifecycle_policy"
require "detector/elasticloadbalancing/unused_classic_load_balancers"
require "detector/elasticloadbalancingv2/unused_load_balancers"
require "detector/elasticsearchservice/unused_domains"
require "detector/kinesis/unused_data_streams"
require "detector/lambda/unused_lambda_functions"
require "detector/mq/unused_mq_brokers"
require "detector/rds/obsolete_snapshots"
require "detector/rds/unused_db_instances"
require "detector/redshift/obsolete_cluster_snapshots"
require "detector/redshift/unused_redshift_cluster"
require "detector/route53resolver/unused_resolvers"
require "detector/sagemaker/unused_sagemaker_domains"
require "detector/sagemaker/unused_sagemaker_notebooks"
require "detector/secretsmanager/unused_secrets"
require "detector/transfer/unused_transfer_servers"
require "detector/vpc/unused_vpc_endpoints"
require "detector/wafv2/unused_web_acls"
require "report_job"

class SprawlDetectorJob < ApplicationJob
  attr_accessor :scan, :account, :role_session, :skip_update_costs, :account_id

  def self.perform_now
    job = SprawlDetectorJob.new
    job.execute
  end

  def execute
    setup

    logger.tagged("Account id=#{account.account_id}") do
      assume_role
      update_cost_and_usage_patterns
      find_detectors_by_cost_and_usage
      finalize
      report_findings
    end
  end

  def setup
    @account_id = ENV.fetch("AWS_ACCOUNT_ID")
    @account = Account.find_by_account_id(account_id)
    if @account.nil?
      logger.error "Unable to find an account with id '#{account_id}'"
      raise "Account #{account_id} not found."
    end

    @scan = Scan.create(account: account, status: :started)
    logger.info "Starting scan ##{scan.id}"
    @scan.skip_audit_logging = false

    # See if there is a profile for this account...
    # Then see if there is a profile for this tenant...
    # Then use the default...
    # But for now just use the default.
    ActiveRecord::Base.logger.level = 1
  end

  def find_detectors_by_cost_and_usage
    services_used = AwsCostLineItem.where(account: account).where("cost > ?", 1).last_30_days.group(:service, :region).sum(:cost).sort_by { |key, cost| -cost }
    logger.info "Found #{services_used.count} services used in the last 7 days."

    services_used.each do |key, cost|
      (service, region) = key
      next if ["global", "NoRegion"].include?(region)
      next if service == "Tax"

      # if cost > 1.0
      logger.info "Investigating #{service} in #{region} which incurred $#{"%.2f" % cost} of costs this period."

      instances = detectors.find_all do |d|
        d.service_name == service
      end

      instances&.each do |detector|
        before = scan.findings.count
        logger.tagged(detector.class) do
          detector.execute(scan, region)
          after = scan.findings.count
          logger.info "Found #{after - before} issues." if before < after
        end
      rescue RuntimeError => e
        logger.error "Unhandled exception from #{detector}"
        logger.error e
      end
      # end
    end

    logger.info "Found #{scan.resources.count} resources and #{scan.findings.count} findings."
    @scan.completed!
  end

  def finalize
    account.findings.where("scan_id <> ?", @scan.id).update_all(status: :closed)
  end

  def assume_role
    if ENV["AWS_PROFILE"]
      logger.info "Skipping assume role and using AWS profile #{ENV["AWS_PROFILE"]}"
      @role_session = Aws::SharedCredentials.new
    else
      role_arn = "arn:aws:iam::#{account_id}:role/BS-SprawlDetector"
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
    return if ENV["SKIP_CE_COST_USAGE"].present?
    client = Aws::CostExplorer::Client.new(credentials: @role_session)
    params = {
      time_period: {
        start: (DateTime.now - 30).strftime("%Y-%m-%d"),
        end: DateTime.now.strftime("%Y-%m-%d")
      },
      granularity: "DAILY",
      metrics: ["NetUnblendedCost"],
      filter: {
        dimensions: {
          key: "LINKED_ACCOUNT",
          values: [account.account_id],
          match_options: ["EQUALS"]
        }
      },
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
          account: account,
          date: Date.parse(result_by_time.time_period.start),
          service: service,
          region: region
        ).save
      end
    end.flatten
    logger.debug "Stored cost & usage data for #{items.count} line items."
  end

  def detectors
    [
      UnusedPrivateAcmCA.new,
      UnusedElastiCacheClusters.new,
      ObsoleteDashboards.new,
      LogGroupsWithoutLogRetention.new,
      UnusedReplicationInstances.new,
      UnusedDirectories.new,
      OverProvisionedTables.new,
      ObsoleteEbsSnapshots.new,
      ObsoleteKeyPairs.new,
      ObsoleteMachineImages.new,
      UnusedClientVpn.new,
      UnusedInstances.new,
      UnusedNatGateways.new,
      UnusedSecurityGroups.new,
      UnusedVolumes.new,
      UnusedVpnConnections.new,
      VpcWithoutS3Endpoint.new,
      RepositoriesWithoutLifecyclePolicy.new,
      UnusedClassicLoadBalancers.new,
      UnusedLoadBalancers.new,
      UnusedDomains.new,
      UnusedDataStreams.new,
      UnusedLambdaFunctions.new,
      UnusedMqBrokers.new,
      ObsoleteSnapshots.new,
      UnusedDbInstances.new,
      ObsoleteClusterSnapshots.new,
      UnusedRedshiftCluster.new,
      UnusedResolvers.new,
      UnusedSagemakerDomains.new,
      UnusedSagemakerNotebooks.new,
      UnusedSecrets.new,
      UnusedTransferServers.new,
      UnusedVpcEndpoints.new,
      UnusedWebAcls.new
    ]
  end

  def report_findings
    ReportJob.new(account.account_id).execute
  end
end
