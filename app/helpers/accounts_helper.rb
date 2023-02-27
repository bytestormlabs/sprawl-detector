# require "cost/cost_calculator"

module AccountsHelper

  def resources_by_account(region, account)
    account_id = account.account_id

    role_arn = "arn:aws:iam::#{account_id}:role/BS-SprawlDetector"
    role_session_name = "byte-storm-labs-sprawl-detector"

    sts = Aws::STS::Client.new(region: "us-east-1")

    credentials = sts.assume_role({
      external_id: account.external_id,
      role_arn: role_arn,
      role_session_name: role_session_name
    })

    results = resource_types(region, credentials).collect do |type_definition|
      resources = type_definition[:client].list_resources([]).map(&:to_h)
      tags = resources.collect { |r| r[type_definition[:tags_key]] }.flatten.map { |tag| tag.slice(:key, :value) }.uniq
      filters = resources.map do |resource|
        type_definition[:filters].map do |filter|
          filter.slice(:name, :type, :key).merge({
            value: resource[filter[:key].to_sym],
            description: type_definition[:descriptor]&.call(resource)
          })
        end
      end.flatten

      type_definition.slice(:type, :name).merge(
        resources: resources,
        filters: filters,
        tags: tags,
      )
    end
  end

  private
  def resource_types(region, credentials)
    [
      {
        type: "AWS::RDS::DBCluster",
        name: "AWS RDS Database Cluster",
        tags_key: :tag_list,
        client: RdsClustersClient.new(region, credentials),
        filters: [
          {
            key: "db_cluster_identifier",
            name: "Database Cluster Identifier",
            type: "attribute"
          }
        ],
        descriptor: Proc.new { |resource|
          ""
        }
      },
      {
        type: "AWS::EC2::AutoScalingGroup",
        name: "AWS EC2 AutoScaling Group",
        tags_key: :tags,
        client: AutoScalingGroupClient.new(region, credentials),
        filters: [
          {
            key: "auto_scaling_group_name",
            filter_name: "auto_scaling_group_names",
            name: "Name",
            type: "attribute"
          }
        ],
        descriptor: Proc.new { |resource|
          resource[:instances].group_by { |x| x[:instance_type] }.map do |instance_type, resources|
            "#{resources.length}x #{instance_type}"
          end.join(", ")
        }
      }
    ]
  end
end
