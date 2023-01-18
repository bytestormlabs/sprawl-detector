require "client/autoscaling_group_client"
require "scheduling/step_executor"
require "concurrent-ruby"
require "base_job"

class ResourcesUpJob < BaseJob
  def execute
    logger.info "entering execute()"
    logger.info " Processing #{scheduled_plan.resource_filters.count} resource filters."

    build_steps(:up)
    assume_role

    each_step do |step, client|
      StepExecutor.new(client, step).up
    end

    logger.info "Finished all steps."
    scheduled_plan_execution.stopped!
  end
end
