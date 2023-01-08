require "aws-sdk-secretsmanager"
require "aws_sdk_operations"
require "assertions"
require "date"

class UnusedSecrets
  include AwsSdkOperations
  include Assertions

  def execute(scan, region)
    expect region, "Paramater 'region' is required."
    expect scan, "Paramater 'scan' is required."

    client = Aws::SecretsManager::Client.new(region: region, credentials: scan.credentials)
    loop_until_finished(client, :list_secrets) do |response|
      response.secret_list.each do |secret|
        process_secret(scan, region, secret)
      end
    end
  end

  def process_secret(scan, region, secret)
    target_date = DateTime.now - 60   # TODO: Refactor this
    resource = scan.build_resource(region, resource_type, secret.name, secret)

    resource.create_finding("aws-secretsmanager-secret-obsolete") if [
      (secret.created_date < target_date),
      (secret.last_accessed_date.nil? || secret.last_accessed_date < target_date)
    ].all?
  end

  def service_name
    "AWS Secrets Manager"
  end

  def resource_type
    "AWS::SecretsManager::Secret"
  end
end
