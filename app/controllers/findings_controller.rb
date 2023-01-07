class FindingsController < ApplicationController
  def index
    findings = @current_user.findings.joins(:status).where(status: {name: "Open"})

    render json: {
      data: ActiveModelSerializers::SerializableResource.new(findings, each_serializer: FindingSerializer),
      message: "Success."
    }
  end
end
