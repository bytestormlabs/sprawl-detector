require "scheduling/step_executor"
require "minitest/autorun"

class StepExecutorTest < ActiveSupport::TestCase
  # rubocop:disable Style/GlobalVars
  logger = Logger.new($STDOUT)
  # rubocop:enable Style/GlobalVars
  class ClientStub
    def list_resources(params)
      [{name: "Resource1"}]
    end

    def stop(params)
      raise Aws::RDS::Errors::ResourceNotFoundFault.new(nil, nil)
    end

    def is_stopped?(t)
      false
    end
  end

  test "it should start & stop the step" do
    plan = scheduled_plans(:scheduled_plan_rds)
    execution = ScheduledPlanExecution.create(scheduled_plan: plan)
    step = execution.steps.create(direction: :down, resource_filter: ResourceFilter.create(scheduled_plan: plan, region: "us-east-1", resource_type: "AWS::RDS::DBCluster"))

    client = Minitest::Mock.new

    client.expect :list_resources, [{name: "Resource1"}], [Array]
    client.expect :is_stopped?, false, [{name: "Resource1"}]
    client.expect :stop, nil, [{name: "Resource1"}]

    2.times do
      client.expect :is_stopped?, true, [{name: "Resource1"}]
    end

    StepExecutor.new(client, step, logger).down

    assert_equal 1, step.number_of_resources_found
    assert_equal 1, step.number_of_resources_completed
    assert_equal 0, step.number_of_resources_skipped
    assert client.verify
  end

  test "it should fail the step if the resource can't be stopped" do
    # skip "focus on other test"
    plan = scheduled_plans(:scheduled_plan_rds)
    execution = ScheduledPlanExecution.create(scheduled_plan: plan)
    step = execution.steps.create(direction: :down, resource_filter: ResourceFilter.new(scheduled_plan: plan, region: "us-east-1", resource_type: "AWS::RDS::DBCluster"))

    # client = Minitest::Mock.new

    StepExecutor.new(ClientStub.new, step, logger).down

    assert step.reload.failed?
    assert_equal 1, step.number_of_resources_found
    assert_equal 0, step.number_of_resources_completed
    assert_equal 1, step.number_of_resources_skipped
  end
end
