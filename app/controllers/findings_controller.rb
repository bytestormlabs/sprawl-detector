class FindingsController < ApplicationController
  def index
    # findings = @current_user.findings.where(list_params)
    @findings = @current_user.findings.joins(:resource)
      .where(region: params[:region])
      .where(account_id: params[:account])
      .where(status: :open)
    # @findings = Finding.joins(:resource, account: [:tenant])
    #   .where(status: :open)
    #   .where(issue_type: params[:issue_type])
    #   .where("resources.region = ?", params[:region])
    #   .where("accounts.account_id = ?", params[:account])

    render json: @findings
  end

  private

  def list_params
    {
      status: (params[:status]&.to_sym || :open)
    }
  end
end
