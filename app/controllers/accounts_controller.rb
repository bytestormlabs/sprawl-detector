class AccountsController < ApplicationController
  def index
    render json: @current_user.tenant.accounts
    # render json: {
    #   data: ActiveModelSerializers::SerializableResource.new(@current_user.accounts, each_serializer: AccountSerializer)
    # }, status: 200
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
      render json: {
        data: @account
      }, status: 200
    else
      render json: {
        data: @account.errors
      }, status: 409
    end
  end

  private

  def create_params
    params.require(:account).permit(:name, :account_id)
  end
end
