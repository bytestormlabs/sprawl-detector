class FindingSerializer < ActiveModel::Serializer
  attributes :id, :message, :resource_id, :region, :status, :metadata

  def status
    object.status&.name
  end
end
