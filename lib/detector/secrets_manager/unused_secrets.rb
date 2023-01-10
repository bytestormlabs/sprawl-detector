require "aws-sdk-secretsmanager"
require "aws_sdk_operations"
require "assertions"
require "date"

class UnusedSecrets
  ISSUE_TYPE = "aws-secretsmanager-secret-obsolete"

  include AwsSdkOperations
  include Assertions

  def execute(scan, region)
    expect region, "Parameter 'region' is required."
    expect scan, "Parameter 'scan' is required."

    client = Aws::SecretsManager::Client.new(region: region, credentials: scan.credentials)
    loop_until_finished(client, :list_secrets) do |response|
      response.secret_list.each do |secret|
        process_secret(scan, region, secret)
      end
    end
  end

  def process_secret(scan, region, secret)
    target_date = DateTime.now - 60   # TODO: Refactor this into some profile/setting
    resource = scan.build_resource(region, resource_type, secret.name, secret)

    resource.create_finding(ISSUE_TYPE) if [
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

  def default_settings
    [
      Setting.create_int(ISSUE_TYPE, "number_of_days_since_last_accessed", "The number of days (since today) to check for this secret being accessed.", 60)
    ]
  end
end
