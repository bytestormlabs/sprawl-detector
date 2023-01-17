require "test_helper"

class ScheduledPlanTest < ActiveSupport::TestCase
  test "validate good scheduled plan" do
    plan = scheduled_plans(:scheduled_plan_rds)

    plan.resource_filters << ResourceFilter.new(
      resource_type: "AWS::RDS::DBCluster",
      region: "us-east-2"
    )

    assert plan.valid?, plan.errors.to_a
  end

  test "save a scheduled plan and ordinal is set automatically" do
    plan = ScheduledPlan.new(account: accounts(:test))

    plan.resource_filters = [ResourceFilter.new(region: "us-east-2", resource_type: "AWS::ECS::Service")]

    assert plan.save, plan.errors.to_a

    assert_equal 1, plan.resource_filters.first.ordinal
  end
end
