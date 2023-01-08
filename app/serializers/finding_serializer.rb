class FindingSerializer < ActiveModel::Serializer
  attributes :id, :message, :status, :estimated_cost

  def status
    object.status&.name
  end
end
