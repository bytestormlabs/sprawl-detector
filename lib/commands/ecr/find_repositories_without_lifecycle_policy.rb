require "aws-sdk-ecr"
require_relative "../command"
class FindRepositoriesWithoutLifecyclePolicy < Command
  def execute(context)
    each_region do |region|
      client = Aws::ECR::Client.new(region: region)

      params = {}

      loop do
        response = client.describe_repositories(params)
        repositories = response.repositories

        repositories.each do |repository|
          check_for_lifecycle_policy(client, context, region, repository)
        end

        break if response.next_token.nil?
        params[:next_token] = response.next_token
      end
    end
  end

  def check_for_lifecycle_policy(client, context, region, repository)
    lifecycle_policy = client.get_lifecycle_policy(repository.to_h.slice(:repository_name))
  rescue Aws::ECR::Errors::LifecyclePolicyNotFoundException
    f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/ecr").find_or_create_by(
      issue_type: "aws-ecr-repository-no-lifecycle-policy",
      resource_id: repository.repository_name,
      account_id: context.aws_account_id
    ).tap do |f|
      f.region = region
      f.message = "Amazon ECR Repository does not have a lifecycle policy."
      f.metadata = repository.to_h
      f.scan = context.scan
    end
    f.save!
  end
end
