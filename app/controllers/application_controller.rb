class ApplicationController < ActionController::API
  respond_to :json
  before_action :authenticate_with_token!
  # skip_before_action :verify_authenticity_token, if: proc { |c| c.request.format == "application/json" }
  # protect_from_forgery with: :null_session, if: proc { |c| c.request.format == "application/json" }
  # skip_before_filter :authenticate_user!
  include Authenticable
end
