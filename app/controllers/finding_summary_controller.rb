class FindingSummaryController < ApplicationController
  def index
    render json: FindingSummary.find_by_tenant(@current_user.tenant.id)
  end
end
