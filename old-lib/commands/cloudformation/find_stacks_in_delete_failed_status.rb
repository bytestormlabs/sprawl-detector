require_relative "../command"
require "aws-sdk-cloudformation"
require "date"

class FindStacksInDeleteFailedStatus < Command
  def execute(context)
    each_region do |region|
      client = Aws::CloudFormation::Client.new(region: region)

      params = {}
      loop do
        response = client.list_stacks(params)
        stack_summaries = response.stack_summaries
        puts "Processing #{stack_summaries.size} stacks in #{region}..."

        stack_summaries.each do |stack|
          # puts stack.stack_status
          next unless stack.stack_status == "DELETE_FAILED"
          check_stack_resources_for_failed_deletion(context, region, client, stack)
        end

        break if response.next_token.nil?
        params[:next_token] = response.next_token
      end
    end
  end

  def check_stack_resources_for_failed_deletion(context, region, client, stack)
    stack_resources = client.describe_stack_resources(stack_name: stack.stack_name).stack_resources
    stack_resources.each do |stack_resource|
      puts stack_resource.resource_status
      if stack_resource.resource_status == "DELETE_FAILED"
        puts "Creating a finding for #{stack_resource}"
        f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/cloudformation").find_or_create_by(
          issue_type: "aws-cloudformation-failed-to-delete-resources",
          resource_id: "#{stack.stack_name}.#{stack_resource.logical_resource_id}",
          aws_account_id: context.aws_account_id, account: Account.find_by_account_id(context.aws_account_id)
        ).tap do |f|
          f.region = region
          f.message = stack_resource.resource_status_reason
          f.metadata = {
            stack: stack.to_h,
            stack_resource: stack_resource.to_h
          }
          f.scan = context.scan
        end
        f.save!
      end
    end
  end
end
