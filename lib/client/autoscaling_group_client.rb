require "aws-sdk-autoscaling"

class AutoScalingGroupClient
  attr_accessor :client

  def initialize(region, credentials)
    @client = Aws::AutoScaling::Client.new(region: region, credentials: credentials)
  end

  def list_resources(filters)
    client.describe_auto_scaling_groups(filters: filters).auto_scaling_groups
  end

  def describe(resource)
    client.describe_auto_scaling_groups(filters: filters).auto_scaling_groups.first
  end

  def start(resource)
  end

  def is_started?(resource)
  end

  def stop(resource)
  end

  def is_stopped?(resource)
  end
end
