require "aws-sdk-scheduler"
require "aws-sdk-cloudformation"

client = Aws::Scheduler::Client.new(region: "us-east-2")
cfn_client = Aws::CloudFormation::Client.new(region: "us-east-2")

exports = cfn_client.list_exports.exports

account_id = "163788863765"

input = JSON.pretty_generate({
  containerOverrides: [
    {
      name: "sprawl-detector",
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
  group_name: "sprawl-detector",
  name: account_id.to_s,
  schedule_expression: "cron(*/15 * * * ? *)",
  state: "ENABLED",
  target: {
    arn: "arn:aws:ecs:us-east-2:163788863765:cluster/Staging-Cluster",
    role_arn: "arn:aws:iam::163788863765:role/Staging-SchedulerRole-resource-scheduler",
    ecs_parameters: {
      task_definition_arn: "arn:aws:ecs:us-east-2:163788863765:task-definition/sprawl-detector",
      network_configuration: {
        awsvpc_configuration: {
          assign_public_ip: "DISABLED",
          security_groups: [
            exports.find { |e| e.name == "Staging-MySqlSecurityGroup" }.value
          ],
          subnets: [
            exports.find { |e| e.name == "Staging-PrivateSubnet1" }.value,
            exports.find { |e| e.name == "Staging-PrivateSubnet2" }.value
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
