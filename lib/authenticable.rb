require "authentication/token"

module Authenticable
  # Devise methods overwrite
  def current_user
    token = request.headers["Authorization"]&.split(/\s+/)&.last
    return nil if token.nil?
    return nil unless Token.is_valid?(token)
    # TODO: Implement token expiration

    result = Token.from_base64(token)
    @current_user = User.find_by_email(result.dig("email"))
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
