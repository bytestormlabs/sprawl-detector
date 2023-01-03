require "aws-sdk-rds"
require_relative "./command"
require_relative "./ec2/find_unused_vpc_endpoints"
require_relative "./ec2/find_obsolete_ebs_snapshots"
require_relative "./ec2/find_obsolete_key_pairs"
require_relative "./ec2/find_obsolete_machine_images"
require_relative "./ec2/find_unused_security_groups"
require_relative "./ec2/find_unused_instances"
require_relative "./ec2/find_unused_volumes"
require_relative "./ecr/find_repositories_without_lifecycle_policy"
require_relative "./cache/find_unused_elasticache_clusters.rb"
require_relative "./elbv2/find_unused_target_groups"
require_relative "./elbv2/find_unused_load_balancers"
require_relative "./es/find_unused_elasticsearch_domains"
require_relative "./mq/find_unused_mq_brokers"
require_relative "./acm/find_unused_private_acm_ca"
require_relative "./rds/find_obsolete_db_snapshots"
require_relative "./rds/find_unused_rds_instances"
require_relative "./redshift/find_obsolete_cluster_snapshots"
require_relative "./sagemaker/find_unused_sagemaker_notebooks"
require_relative "./cloudwatch/find_obsolete_cloudwatch_dashboards"
require_relative "./cloudwatch/find_log_groups_with_unacceptable_retention_periods"
require_relative "./secrets/find_unused_secrets"
require_relative "./transfer/find_unused_transfer_servers"
require_relative "./dms/find_unused_replication_instances"
require_relative "./redshift/find_unused_redshift_clusters"
require_relative "./route53/find_unused_route53_resolvers.rb"
require_relative "./cloudformation/find_stacks_in_delete_failed_status"

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
