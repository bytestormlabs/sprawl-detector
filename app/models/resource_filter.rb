require "forwardable"

class ResourceFilter < ActiveRecord::Base
  extend Forwardable

  default_scope { order(ordinal: :asc) }

  validates :ordinal, presence: true
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
    ),
    ResourceConfiguration.new(
      "AWS::AutoScaling::AutoScalingGroup",
      [
        "auto_scaling_group_names"
      ],
      "AWS AutoScaling Groups"
    ),
    ResourceConfiguration.new(
      "AWS::ECS::Service",
      [
        "cluster",
        "services"
      ],
      "AWS ECS Services"
    )
  ].freeze

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

  validate :ensure_filters_have_valid_names

  before_validation do |rf|
    rf.ordinal = rf.scheduled_plan.resource_filters.count + 1 if rf.ordinal.nil?
  end

  def friendly_name
    RESOURCE_CONFIGURATIONS.find { |d| d.resource_type == resource_type }&.name
  end

  def ensure_filters_have_valid_names
    filters.each do |filter|
      unless filter.is_tag_based?
        resource_configuration = RESOURCE_CONFIGURATIONS.find { |d| d.resource_type == resource_type }
        next if resource_configuration.nil?
        unless resource_configuration.filters.include?(filter.name)
          errors.add(:filters, "Invalid attribute '#{filter.name}'. Allowed values are #{resource_configuration.filters.join(", ")}.")
          filter.errors.add(:name, "Invalid attribute '#{filter.name}'. Allowed values are #{resource_configuration.filters.join(", ")}.")
        end
      end
    end
  end

  def self.resource_configurations
    RESOURCE_CONFIGURATIONS
  end

  def build_filter_params
    filters.each do |filter|
      if filter.is_tag_based?
        params[:filters] = (params[:filters] || [])
        params[:filters] << filter.to_filter
      else
        params[filter.name.to_sym] = filter.value
      end
    end
  end
end
