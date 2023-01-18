require "client/autoscaling_group_client"
require "scheduling/step_executor"
require "concurrent-ruby"

class BaseJob < ApplicationJob
  attr_accessor :account, :scheduled_plan
  attr_accessor :role_session, :steps
  attr_accessor :scheduled_plan_execution

  def initialize
    @account = Account.find_by_account_id(ENV.fetch("AWS_ACCOUNT_ID"))
    @scheduled_plan = ScheduledPlan.find(ENV.fetch("SCHEDULE_PLAN_ID"))
    @scheduled_plan_execution = ScheduledPlanExecution.create(scheduled_plan: @scheduled_plan)
  end

  def assume_role
    logger.debug "entering assume_role()"
    sts = Aws::STS::Client.new(region: "us-east-1")
    @role_session = sts.assume_role({
      external_id: account.external_id,
      role_arn: "arn:aws:iam::#{account.account_id}:role/BS-ResourceScheduler",
      role_session_name: "byte-storm-labs-resource-scheduler" # TODO: Refactor this
    })
    logger.debug("exiting assume_role()")
  end

  def build_steps(direction)
    logger.debug "Building steps to go #{direction}"
    @steps = scheduled_plan.resource_filters.map do |resource_filter|
      Step.create(resource_filter: resource_filter, scheduled_plan_execution: scheduled_plan_execution, direction: direction, status: :started)
    end
    logger.debug "Created #{steps.count} steps."
  end

  def each_step
    steps.each do |step|
      logger.debug "Starting step #{step}"
      client = client_for(step.resource_filter.resource_type).new(step.resource_filter.region, role_session)
      yield(step, client)
      logger.debug "Finished."
    end
  end

  def client_for(resource_type)
    {
      "AWS::AutoScaling::AutoScalingGroup" => AutoScalingGroupClient
    }[resource_type]
  end
end
