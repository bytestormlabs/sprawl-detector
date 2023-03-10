require "aws-sdk-autoscaling"

class AutoScalingGroupClient
  attr_accessor :client

  def initialize(region, credentials)
    @client = Aws::AutoScaling::Client.new(region: region, credentials: credentials)
  end

  def list_resources(filters)
    # Find any tag or
    params = {}

    client.describe_auto_scaling_groups(params).auto_scaling_groups
  end

  def describe(resource)
    client.describe_auto_scaling_groups(auto_scaling_group_names: [resource[:auto_scaling_group_name]]).auto_scaling_groups.first
  end

  def start(resource)
    # Find the autoscaling group by name and update the desired capacity to match
    params = resource.to_h.slice(:auto_scaling_group_name, :min_size, :max_size, :desired_size)
    client.update_auto_scaling_group(params)
  end

  def is_started?(resource)
    count = describe(resource).instances.count { |x| x[:lifecycle_state] == "InService" }
    resource[:desired_capacity] == count
  end

  def stop(resource)
    client.update_auto_scaling_group(
      auto_scaling_group_name: resource[:auto_scaling_group_name],
      min_size: 0,
      max_size: 0,
      desired_capacity: 0
    )
  end

  def is_stopped?(resource)
    describe(resource).instances.count == 0
  end
end
