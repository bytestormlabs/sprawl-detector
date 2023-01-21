class FindingsController < ApplicationController
  before_action :authenticate_with_token!, only: [:update, :destroy]

  def index
    # findings = @current_user.findings.where(list_params)
    @findings = Finding.joins(:resource, account: [ :tenant ])
      .where(status: :open)
      .where(issue_type: params[:issue_type])
      .where("resources.region = ?", params[:region])
      .where("accounts.account_id = ?", params[:account])

    puts "Found #{@findings.size} findings."
    render json: {
      data: ActiveModelSerializers::SerializableResource.new(@findings, each_serializer: FindingSerializer),
      message: "Success."
    }
  end

  private

  def list_params
    {
      status: (params[:status]&.to_sym || :open)
    }
  end
end
