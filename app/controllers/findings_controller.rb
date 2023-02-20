class FindingsController < ApplicationController
  def index
    @findings = @current_user.findings.joins(resource: [:account])
      .where("resources.region" => params[:region])
      .where("accounts.account_id" => params[:account])
      .where(issue_type: params[:issue_type])
      .where(status: :open)

    render json: @findings
  end
end
