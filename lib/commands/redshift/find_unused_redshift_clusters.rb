require "aws-sdk-rds"
require_relative "../command"

class FindUnusedRedshiftClusters < Command
  def execute(context)
    each_region do |region|
      rds_client = Aws::Redshift::Client.new(region: region)
      clusters = rds_client.describe_clusters.clusters.find_all do |cluster|
        # Must be available
        cluster.cluster_status == "available"
      end

      clusters.each do |cluster|
        cluster_identifier = cluster.cluster_identifier

        # Execute the unused checks first...
        checks.each do |check|
          matches = check.matches(context, region, cluster_identifier)

          context.logger.debug "checking #{check} #{matches}"
          if matches
            f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/rds").find_or_create_by(
              issue_type: check.issue_type,
              resource_id: cluster_identifier,
              aws_account_id: context.aws_account_id, account: Account.find_by_account_id(context.aws_account_id)
            ).tap do |f|
              f.region = region
              f.message = check.message
              f.metadata = cluster.to_h
              f.scan = context.scan
            end
            f.save!
            break
          end
        end
      end
    end
  end

  private

  def checks
    [
      CloudWatchCheck.new({
        metric: "DatabaseConnections",
        issue_type: "aws-redshift-cluster-unused",
        statistic: "Maximum",
        namespace: "AWS/Redshift",
        attribute: "ClusterIdentifier",
        period: (60 * 60 * 2),
        message: "No database connections have made in the last week."
      })
    ]
  end
end
