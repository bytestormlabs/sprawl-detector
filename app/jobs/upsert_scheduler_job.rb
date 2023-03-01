require "aws-sdk-cloudformation"
require "aws-sdk-scheduler"

class UpsertSchedulerJob < ApplicationJob
  queue_as :default

  attr_accessor :enabled, :region, :environment, :target_account_id

  def initialize(*args)
    super
    @enabled = ["staging", "prod"].include?(ENV["RAILS_ENV"]) || ENV["USE_AWS_SCHEDULER"].present?
    @region = ENV.fetch("AWS_REGION", "us-east-2")
    @environment = ENV.fetch("AWS_ENVIRONMENT", "Staging")
    @target_account_id = ENV.fetch("TARGET_AWS_ACCOUNT_ID", "163788863765")
  end

  def perform(*args)
    logger.debug "entering perform()"
    return if !enabled

    id = args.first

    begin
      plan = ScheduledPlan.find(id)
      client = Aws::Scheduler::Client.new(region: region)

      [
        ["up", "ResourcesUpJob.perform_now", plan.up_schedule],
        ["down", "ResourcesDownJob.perform_now", plan.down_schedule]
      ].each do |params|
        (direction, command, schedule) = params
        schedule_name = [
          plan.account.account_id,
          plan.id,
          direction
        ].join("_")

        begin
          logger.debug "Preparing to update schedule for #{schedule_name}"
          request = build_request(schedule_name, schedule, plan.id, command)
          client.update_schedule(request)
        rescue Aws::Scheduler::Errors::ResourceNotFoundException
          begin
            client.create_schedule(request)
          rescue => e
            logger.error e
          end
        rescue => e
          logger.error e
        end
      end
    end
  end

  private

  def build_request(name, cron, id, command)
    image = "sprawl-detector"
    cfn_client = Aws::CloudFormation::Client.new(region: region)

    exports = cfn_client.list_exports.exports

    {
      description: "Resource scheduling for #{name}",
      flexible_time_window: {
        mode: "OFF"
      },
      group_name: image.to_s,
      name: name,
      schedule_expression: "cron(#{cron})",
      schedule_expression_timezone: "America/New_York",
      state: "ENABLED",
      target: {
        arn: "arn:aws:ecs:#{region}:#{target_account_id}:cluster/#{environment}-Cluster",
        role_arn: "arn:aws:iam::#{target_account_id}:role/#{environment}-SchedulerRole",
        ecs_parameters: {
          task_definition_arn: "arn:aws:ecs:#{region}:#{target_account_id}:task-definition/#{image}",
          network_configuration: {
            awsvpc_configuration: {
              assign_public_ip: "DISABLED",
              security_groups: [
                exports.find { |e| e.name == "#{environment}-MySqlSecurityGroup" }.value
              ],
              subnets: [
                exports.find { |e| e.name == "#{environment}-PrivateSubnet1" }.value,
                exports.find { |e| e.name == "#{environment}-PrivateSubnet2" }.value
              ]
            }
          }
        },
        input: JSON.pretty_generate({
          containerOverrides: [
            {
              name: image.to_s,
              command: [
                "./bin/rails", "runner", command
              ],
              environment: [
                {
                  name: "AWS_ACCOUNT_ID",
                  value: target_account_id
                },
                {
                  name: "SCHEDULE_PLAN_ID",
                  value: id.to_s
                }
              ]
            }
          ]
        })
      }
    }
  end
end
