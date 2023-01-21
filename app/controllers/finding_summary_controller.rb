class FindingSummaryController < ApplicationController
  before_action :authenticate_with_token!, only: [:update, :destroy]

  def index
    render json: FindingSummary.find_by_tenant(3)
  end
end
