require "aws-sdk-secretsmanager"
require_relative "../command"
require "date"

class FindUnusedSecrets < Command
  def execute(context)
    context.logger.debug "entering execute"

    each_region do |region|
      client = Aws::SecretsManager::Client.new(region: region)

      response = client.list_secrets
      secret_list = response.secret_list

      secret_list.each do |secret|
        target_date = (DateTime.now - 60)
        if secret.created_date < target_date && (secret.last_accessed_date.nil? || secret.last_accessed_date < target_date)
          f = Finding.create_with(status: Status.find_by_name("Open"), category: "aws/secretsmanager").find_or_create_by(
            issue_type: "aws-secretsmanager-secret-obsolete",
            resource_id: secret.name,
            aws_account_id: context.aws_account_id, account: Account.find_by_account_id(context.aws_account_id)
          ).tap do |f|
            f.region = region
            f.message = "AWS SecretsManager secret hasn't been accessed in 60 days."
            f.metadata = secret.to_h
            f.scan = context.scan
          end
          f.save!
        end
      end
    end
  end
end
