class AccountSerializer < ActiveModel::Serializer
  attributes :id, :account_id, :external_id, :account_type

  def account_type
    "aws"
  end
end
