require "accounts/account_validator"
require "client/rds_clusters_client"
require "client/autoscaling_group_client"

class AccountsController < ApplicationController
  def index
    render json: @current_user.tenant.accounts
  end

  def show
    # TODO: Check this user is allowed to see this.
    render json: Account.find(params[:id])
  end

  def destroy
    render json: Account.find(params[:id]).destroy
  end

  def create
    if params[:account][:account_id].nil?
      render status: 400,
        json: {message: "Account must contain the account id."}
      return
    end

    if params[:account][:account_id]
      duplicate_account = Account.find_by_account_id(params[:account][:account_id])
      if duplicate_account
        render status: 400,
          json: {message: "Account ID #{params[:account][:account_id]} already exists."}
        return
      end
    end

    @account = Account.create(create_params.merge(tenant: @current_user.tenant))
    @account.create_random_external_id
    if @account.save
      render json: @account, status: 200
    else
      render json: {
        errors: @account.errors
      }, status: 409
    end
  end

  def validate
    validator = Accounts::AccountValidator.new(Account.find_by_account_id(params[:id]))
    result = validator.validate

    render json: result, status: result.success ? 200 : 409
  end

  def list_resources
    id = params[:id]

    unless @current_user.tenant.accounts.pluck(:id).include?(id.to_i)
      render json: {
        message: "Unauthenticated."
      }, status: 403
      return
    end

    region = params[:region] || "us-east-2"
    @account = Account.find(id)
    account_id = @account.account_id

    role_arn = "arn:aws:iam::#{account_id}:role/BS-SprawlDetector"
    role_session_name = "byte-storm-labs-sprawl-detector"

    sts = Aws::STS::Client.new(region: "us-east-1")
    credentials = sts.assume_role({
      external_id: @account.external_id,
      role_arn: role_arn,
      role_session_name: role_session_name
    })

    results = [
      RdsClustersClient.new(region, credentials),
      AutoScalingGroupClient.new(region, credentials),
    ].collect do |client|
      client.list_resources([]).map(&:to_h)
    end

    render json: results
  end

  private

  def create_params
    params.require(:account).permit(:name, :account_id)
  end
end
