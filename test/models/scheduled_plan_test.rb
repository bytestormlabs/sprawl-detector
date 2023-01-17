require "test_helper"

class ScheduledPlanTest < ActiveSupport::TestCase
  test "validate good scheduled plan" do
    plan = scheduled_plans(:scheduled_plan_rds)

    assert plan, "this shouldnt be nil"
  end
end
