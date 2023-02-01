require "aws-sdk-sts"

class AccountValidator
  ValidationResult = Struct.new(:successful, :message)

  attr_accessor :account

  def initialize(account)
    @account = account
  end

  def account_id
    @account.account_id
  end

  def validate
    role_arn = "arn:aws:iam::#{account_id}:role/BS-SprawlDetector"
    role_session_name = "byte-storm-labs-sprawl-detector"

    sts = Aws::STS::Client.new(region: "us-east-1")

    begin
      sts.assume_role({
        external_id: @account.external_id,
        role_arn: role_arn,
        role_session_name: role_session_name
      })
      ValidationResult.new(true, nil)
    rescue => e
      ValidationResult.new(false, e.message)
    end
  end
end
