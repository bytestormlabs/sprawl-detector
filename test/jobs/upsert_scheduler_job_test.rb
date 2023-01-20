require "test_helper"
require "base_aws_integration_test"

class UpsertSchedulerJobTest < BaseAwsIntegrationTest
  test "upsert schedule calls AWS Scheduler API" do
    job = UpsertSchedulerJob.new
    job.enabled = true
    job.perform(scheduled_plans(:scheduled_plan_rds).id)
  end
end
