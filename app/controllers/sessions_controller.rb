class SessionsController < ApplicationController
  before_action :authenticate_with_token!, except: [:create]

  before_action :ensure_params_exist

  respond_to :json

  def create
    resource = User.find_for_database_authentication(
      email: params[:user][:email]
    )
    return invalid_login_attempt unless resource

    if resource.valid_password?(params[:user][:password])
      sign_in(:user, resource)
      resource.authentication_token = Token.create(email: params[:user][:email]).to_base64
      puts "setting authentication_token: #{resource.authentication_token}"
      render json: {
        data: ActiveModelSerializers::SerializableResource.new(resource)
      }, status: 200
      return
    end
    invalid_login_attempt
  end

  def destroy
    resource = current_user
    resource.authentication_token = nil
    resource.save
    head 204
  end

  protected

  def ensure_params_exist
    return unless params[:user].blank?
    render json: {
      success: false,
      message: "missing user parameter"
    }, status: 422
  end

  def invalid_login_attempt
    warden.custom_failure!
    render json: {
      success: false,
      message: "Error with your email or password"
    }, status: 401
  end
end
