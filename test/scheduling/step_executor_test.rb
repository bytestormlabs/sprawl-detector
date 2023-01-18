require "scheduling/step_executor"
require "minitest/autorun"

class StepExecutorTest < ActiveSupport::TestCase
  test "it should start & stop the step" do
    plan = scheduled_plans(:scheduled_plan_rds)
    execution = ScheduledPlanExecution.create(scheduled_plan: plan)
    step = execution.steps.create(direction: :down, resource_filter: ResourceFilter.create(scheduled_plan: plan, region: "us-east-1", resource_type: "AWS::RDS::DBCluster"))

    client = Minitest::Mock.new

    client.expect :list_resources, [{name: "Resource1"}, {name: "Resource2"}], [Array]
    2.times do
      # Order isn't guaranteed because we're using concurrent -- so we have to use
      # a custom block to verify parameters
      client.expect :stop, nil do |params|
        assert_includes ["Resource1", "Resource2"], params[:name]
      end
      client.expect :is_stopped?, true do |params|
        assert_includes ["Resource1", "Resource2"], params[:name]
      end
    end

    StepExecutor.new(client, step).down
    assert client.verify

    assert_equal 2, step.number_of_resources_found
    assert_equal 2, step.number_of_resources_completed
    assert_equal 0, step.number_of_resources_skipped
  end

  test "it should fail the step if the resource can't be stopped" do
    plan = scheduled_plans(:scheduled_plan_rds)
    execution = ScheduledPlanExecution.create(scheduled_plan: plan)
    step = execution.steps.create(direction: :down, resource_filter: ResourceFilter.new(scheduled_plan: plan, resource_type: "AWS::RDS::DBCluster"))

    # client = Minitest::Mock.new

    class ClientStub
      def list_resources(params)
        [{name: "Resource1"}]
      end
      def stop(params)
        raise Aws::RDS::Errors::ResourceNotFoundFault.new(nil, nil)
      end
    end

    StepExecutor.new(ClientStub.new, step).down

    assert step.reload.failed?
    assert_equal 1, step.number_of_resources_found
    assert_equal 0, step.number_of_resources_completed
    assert_equal 1, step.number_of_resources_skipped
  end
end
