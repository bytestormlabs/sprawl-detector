require "aws-sdk-scheduler"
require "aws-sdk-cloudformation"

client = Aws::Scheduler::Client.new(region: "us-east-2")
cfn_client = Aws::CloudFormation::Client.new(region: "us-east-2")

exports = cfn_client.list_exports.exports

account_id = "163788863765"
region = "us-east-2"
image = "sprawl-detector"
environment = "Staging"

input = JSON.pretty_generate({
  containerOverrides: [
    {
      name: "#{image}",
      command: [
        "./bin/rails", "runner", "SprawlDetectorJob.perform_now"
      ],
      environment: [
        {
          name: "AWS_ACCOUNT_ID",
          value: account_id
        }
      ]
    }
  ]
})

request = {
  description: "Periodic sprawl detection for #{account_id}",
  flexible_time_window: {
    mode: "OFF"
  },
  group_name: "#{image}",
  name: account_id.to_s,
  schedule_expression: "cron(*/15 * * * ? *)",
  state: "ENABLED",
  target: {
    arn: "arn:aws:ecs:#{region}:#{account_id}:cluster/#{environment}-Cluster",
    role_arn: "arn:aws:iam::#{account_id}:role/#{environment}-SchedulerRole-#{image}",
    ecs_parameters: {
      task_definition_arn: "arn:aws:ecs:#{region}:#{account_id}:task-definition/#{image}",
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
    input: input
  }
}

begin
  client.update_schedule(request)
rescue Aws::Scheduler::Errors::ResourceNotFoundException => e
  client.create_schedule(request)
end
