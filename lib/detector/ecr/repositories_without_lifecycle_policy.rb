require "detector/support/cloudwatch"
require "aws-sdk-ecr"

class RepositoriesWithoutLifecyclePolicy
  ISSUE_TYPE = "aws-ecr-repository-no-lifecycle-policy"

  include AwsSdkOperations
  include Assertions
  include Cloudwatch

  def execute(scan, region)
    expect region, "parameter 'region' is required."
    expect scan, "parameter 'scan' is required."

    client = Aws::ECR::Client.new(region: region, credentials: scan.credentials)
    loop_until_finished(client, :describe_repositories) do |response|
      response.repositories.each do |repository|
        images = client.describe_images(repository.to_h.slice(:repository_name, :registry_id)).image_details
        resource = scan.build_resource(region, resource_type, repository.repository_name, {
          repository: repository.to_h,
          images: images.map(&:to_h)
        })
        resource.create_finding(scan, ISSUE_TYPE) unless has_lifecycle_policy?(client, repository)
      end
    end
  end

  def has_lifecycle_policy?(client, repository)
    client.get_lifecycle_policy(repository.to_h.slice(:repository_name, :registry_id))
    true
  rescue Aws::ECR::Errors::LifecyclePolicyNotFoundException
    false
  end

  def service_name
    "Amazon EC2 Container Registry (ECR)"
  end

  def resource_type
    "AWS::ECR::Repository"
  end

  def default_settings
    []
  end
end
