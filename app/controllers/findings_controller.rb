class FindingsController < ApplicationController
  def index
    findings = Finding.all.includes(:status)

    render json: {
      data: ActiveModelSerializers::SerializableResource.new(findings, each_serializer: FindingSerializer),
      message: "Success."
    }
  end
end
