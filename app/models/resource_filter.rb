require "forwardable"
# require_relative "../strategy/autoscaling_resource_strategy"
# require_relative "../strategy/rds_instance_resource_strategy"
# require_relative "../strategy/rds_cluster_resource_strategy"
# require_relative "../strategy/ecs_service_resource_strategy"

class ResourceFilter < ActiveRecord::Base
  extend Forwardable

  # def_delegators :strategy, :friendly_name

  belongs_to :scheduled_plan
  has_many :filters

  ResourceConfiguration = Struct.new(:resource_type, :filters, :name)

  RESOURCE_CONFIGURATIONS = [
    ResourceConfiguration.new(
      "AWS::RDS::DBCluster",
      [
        "clone-group-id",
        "db-cluster-id",
        "domain",
        "engine"
      ],
      "AWS RDS Database Clusters"
    )
  ]

  validates :resource_type, presence: true, inclusion: {
    in: RESOURCE_CONFIGURATIONS.map(&:resource_type)
  }

  validates :region, presence: true, inclusion: {
    in: [
      "us-east-1",
      "us-east-2",
      "us-west-1",
      "us-west-2",
      "af-south-1",
      "ap-east-1",
      "ap-south-1",
      "ap-south-2",
      "ap-southeast-1",
      "ap-southeast-2",
      "ap-southeast-3",
      "ap-northeast-1",
      "ap-northeast-2",
      "ap-northeast-3",
      "ca-central-1"
    ]
  }
  # validate :ensure_filters_have_valid_names

  # def strategy
  #   [
  #     RdsInstanceResourceStrategy.new(self),
  #     EcsServiceResourceStrategy.new(self),
  #     RdsClusterResourceStrategy.new(self),
  #     AutoScalingResourceStrategy.new(self)
  #   ].find do |strategy|
  #     strategy.applies_to?(resource_type)
  #   end
  # end
  #
  # def ensure_filters_have_valid_names
  #   filters.each do |filter|
  #     if !filter.is_tag_based?
  #       unless strategy.available_filters.include? filter.name
  #         errors.add(:filters, "Invalid attribute '#{filter.name}'. Allowed values are #{strategy.available_filters.join(", ")}.")
  #         filter.errors.add(:name, "Invalid attribute '#{filter.name}'. Allowed values are #{strategy.available_filters.join(", ")}.")
  #       end
  #     end
  #   end
  # end
end
