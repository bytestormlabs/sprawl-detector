class FindingsController < ApplicationController
  def index
    findings = @current_user.findings.where(list_params)

    render json: {
      data: ActiveModelSerializers::SerializableResource.new(findings, each_serializer: FindingSerializer),
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
