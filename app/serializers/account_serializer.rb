class AccountSerializer < ActiveModel::Serializer
  attributes :id, :name, :account_id, :external_id, :account_type, :last_scanned

  def account_type
    "aws"
  end

  def last_scanned
    object&.scans&.last&.updated_at
  end
end
