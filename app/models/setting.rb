class Setting < ApplicationRecord
  belongs_to :account, optional: true
  belongs_to :tenant, optional: true
  belongs_to :issue_type, optional: true

  enum :data_type, %i[integer string boolean]
  validates :key, presence: true
  validates :value, presence: true

  # validate :data_type_matches_value

  # def self.get_int(scan, key)
  #   [
  #     Setting.where(account_id: scan.account.id).where(key: key),
  #     Setting.where(tenant_id: scan.account.tenant.id).where(key: key),
  #     Setting.where("account_id IS NULL AND tenant_id IS NULL")
  #   ].find(&:count).value.to_i
  # end

  # def data_type_matches_value
  #   case data_type
  #   when "integer"
  #     errors.add(:value, "Value must be a number.") unless /\d+/.match?(value&.strip)
  #   when "boolean"
  #     errors.add(:value, "Value must be either true or false.") unless ["true", "false"].include? value
  #   end
  # end

  def self.create_int(prefix, key, description, value)
    Setting.new(key: [prefix, key].join("."), description: description, value: value)
  end
end
