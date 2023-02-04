class ApplicationController < ActionController::API
  respond_to :json
  before_action :authenticate_with_token!
  # skip_before_filter :verify_authenticity_token
  # protect_from_forgery with: :null_session
  # skip_before_filter :authenticate_user!
  before_action :cors_preflight_check
  after_action :cors_set_access_control_headers

  include Authenticable

  def cors_set_access_control_headers
    headers["Access-Control-Allow-Origin"] = "*"
    headers["Access-Control-Allow-Methods"] = "POST, PUT, DELETE, GET, OPTIONS"
    headers["Access-Control-Request-Method"] = "*"
    headers["Access-Control-Allow-Headers"] = "Origin, X-Requested-With, Content-Type, Accept, Authorization"
  end

  def cors_preflight_check
    if request.method == :options
      puts "Responding to OPTIONS"
      headers["Access-Control-Allow-Origin"] = "*"
      headers["Access-Control-Allow-Methods"] = "POST, GET, OPTIONS, DELETE, PUT"
      headers["Access-Control-Allow-Headers"] = "*"
      headers["Access-Control-Max-Age"] = "1"
      render text: "", content_type: "text/plain"
    end
  end
end
