require "accounts/account_validator"

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

  private

  def create_params
    params.require(:account).permit(:name, :account_id)
  end
end
