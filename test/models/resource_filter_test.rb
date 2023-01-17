require "test_helper"

class ResourceFilterTest < ActiveSupport::TestCase
  test "junk RDS filter is invalid" do
    plan = scheduled_plans(:scheduled_plan_rds)
    resource_filter = ResourceFilter.new(scheduled_plan: plan, region: "us-east-1", resource_type: "AWS::RDS::DBCluster")
    resource_filter.filters << Filter.new(
      name: "fdadasa", value: "adsfasfafaf", filter_type: "attribute"
    )
    assert resource_filter.invalid?, "Should be invalid"
  end

  test "db-cluster-id RDS filter is valid" do
    plan = scheduled_plans(:scheduled_plan_rds)
    resource_filter = ResourceFilter.new(scheduled_plan: plan, region: "us-east-1", resource_type: "AWS::RDS::DBCluster")
    resource_filter.filters << Filter.new(
      name: "db-cluster-id", value: "adsfasfafaf", filter_type: "attribute"
    )
    assert resource_filter.valid?, resource_filter.errors.to_a
  end

  test "autoscaling group name is a valid filter" do
    plan = scheduled_plans(:scheduled_plan_rds)
    resource_filter = ResourceFilter.new(scheduled_plan: plan, region: "us-east-1", resource_type: "AWS::AutoScaling::AutoScalingGroup")
    resource_filter.filters << Filter.new(
      name: "auto_scaling_group_names", value: "adsfasfafaf", filter_type: "attribute"
    )
    assert resource_filter.valid?, resource_filter.errors.to_a
  end
end
