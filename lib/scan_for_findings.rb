require "aws-sdk-rds"
require "commands/command"
require "commands/ec2/find_unused_vpc_endpoints"
require "commands/ec2/find_obsolete_ebs_snapshots"
require "commands/ec2/find_obsolete_key_pairs"
require "commands/ec2/find_obsolete_machine_images"
require "commands/ec2/find_unused_security_groups"
require "commands/ec2/find_unused_nat_gateways"
require "commands/ec2/find_unused_instances"
require "commands/ec2/find_unused_volumes"
require "commands/ecr/find_repositories_without_lifecycle_policy"
require "commands/cache/find_unused_elasticache_clusters.rb"
require "commands/elbv2/find_unused_target_groups"
require "commands/elbv2/find_unused_load_balancers"
require "commands/es/find_unused_elasticsearch_domains"
require "commands/mq/find_unused_mq_brokers"
require "commands/acm/find_unused_private_acm_ca"
require "commands/rds/find_obsolete_db_snapshots"
require "commands/rds/find_unused_rds_instances"
require "commands/redshift/find_obsolete_cluster_snapshots"
require "commands/sagemaker/find_unused_sagemaker_domains"
require "commands/sagemaker/find_unused_sagemaker_endpoints"
require "commands/sagemaker/find_unused_sagemaker_notebooks"
require "commands/cloudwatch/find_obsolete_cloudwatch_dashboards"
require "commands/cloudwatch/find_log_groups_with_unacceptable_retention_periods"
require "commands/secrets/find_unused_secrets"
require "commands/transfer/find_unused_transfer_servers"
require "commands/dms/find_unused_replication_instances"
require "commands/redshift/find_unused_redshift_clusters"
require "commands/route53/find_unused_route53_resolvers.rb"
require "commands/cloudformation/find_stacks_in_delete_failed_status"

class ScanForFindings < Command
  def execute(context)
    context.logger.debug "entering execute"

    scan = Scan.new
    puts scan.save!

    context.scan = scan

    FindUnusedVpcEndpounts.new.execute(context)
    FindUnusedLoadBalancers.new.execute(context)

    # CloudFormation
    FindStacksInDeleteFailedStatus.new.execute(context)

    # Route53 Resolvers
    FindUnusedRoute53Resolvers.new.execute(context)

    # Amazon Database Migration Service
    FindUnusedReplicationInstances.new.execute(context)

    # AWS Transfer
    FindUnusedTransferServers.new.execute(context)

    # AWS SecretsManager
    FindUnusedSecrets.new.execute(context)

    # ElasticSearch Domains
    FindUnusedElasticSearchDomains.new.execute(context)

    # Private ACM CAs
    FindUnusedAcmPrivateCA.new.execute(context)

    # ElastiCache
    FindUnusedElastiCacheClusters.new.execute(context)

    # Redshift checks
    FindObsoleteClusterSnapshots.new.execute(context)
    FindUnusedRedshiftClusters.new.execute(context)

    # Cloudwatch checks
    FindLogGroupsWithUnacceptableRetentionPeriods.new.execute(context)
    FindObsoleteCloudwatchDashboard.new.execute(context)

    # AmazonMQ
    FindUnusedMqBrokers.new.execute(context)

    # EC2 related checks
    FindObsoleteKeyPairs.new.execute(context)
    FindUnusedVolumes.new.execute(context)
    FindObsoluteEbsSnapshots.new.execute(context)
    FindUnusedNatGateways.new.execute(context)
    FindUnusedSecurityGroups.new.execute(context)
    FindUnusedInstances.new.execute(context)
    FindObsoleteMachineImages.new.execute(context)
    FindUnusedTargetGroups.new.execute(context)

    # ECR checks
    FindRepositoriesWithoutLifecyclePolicy.new.execute(context)

    # RDS related checks
    FindObsoleteDbSnapshots.new.execute(context)
    FindUnusedRdsInstances.new.execute(context)

    # SageMaker checks
    FindUnusedSagemakerNotebooks.new.execute(context)
    FindUnusedSagemakerDomains.new.execute(context)

    puts "Updating where account_id = #{context.aws_account_id} and scan_id < #{scan.id}"

    puts Finding.where("account_id = ? AND (scan_id != ? OR scan_id IS NULL)", context.aws_account_id, scan.id).update_all(status_id: Status.find_by_name('Closed').id)

    context.logger.debug "exiting execute"
  end
end
