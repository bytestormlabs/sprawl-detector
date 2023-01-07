class FindingsController < ApplicationController
  def index
    findings = @current_user.findings.joins(:status).where(status: list_params)

    render json: {
      data: ActiveModelSerializers::SerializableResource.new(findings, each_serializer: FindingSerializer),
      message: "Success."
    }
  end

  private
  def list_params
    {
      name: (params[:status] || "Open")
    }
  end
end
