class RegistrationsController < ApplicationController
  before_action :authenticate_with_token!, only: [:update, :destroy]
  respond_to :json

  def create
    if params[:user][:email].nil?
      render status: 400,
        json: {message: "User request must contain the user email."}
      return
    elsif params[:user][:password].nil?
      render status: 400,
        json: {message: "User request must contain the user password."}
      return
    elsif params[:tenant].nil? || params[:tenant][:name].nil?
      render status: 400,
        json: {message: "User request must contain the company name."}
      return
    end

    if params[:user][:email]
      duplicate_user = User.find_by_email(params[:user][:email])
      unless duplicate_user.nil?
        render status: 409,
          json: {message: "Duplicate email. A user already exists with that email address."}
        return
      end
    end

    @tenant = Tenant.create(params.require(:tenant).permit(:name))
    @tenant.save!
    @user = User.create(user_sign_up_params.merge(tenant: @tenant))

    if @user.save
      render json: {
        data: ActiveModelSerializers::SerializableResource.new(@user, each_serializer: UserSerializer),
        message: "Success."
      }
    else
      render status: 400,
        json: {message: @user.errors.full_messages}
    end
  end

  private

  def user_sign_up_params
    params.require(:user).permit(:email, :username, :password)
  end
end
