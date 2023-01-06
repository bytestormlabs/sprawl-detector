class AccountsController < ActionController::Base
  def save
    user = User.new(payload)
  end

  private
  def payload
    params.permit(:email, :given_name, :family_name)
  end
end
