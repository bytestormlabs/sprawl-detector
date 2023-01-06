module Authenticable
  # Devise methods overwrite
  def current_user
    @current_user ||= User.find_by(authentication_token: request.headers["Authorization"])
  end

  def authenticate_with_token!
    unless user_signed_in?
      render json: {errors: "Not authenticated."},
        status: :unauthorized
    end
  end

  def user_signed_in?
    current_user.present?
  end
end
