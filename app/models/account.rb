require "faker"
class Account < ApplicationRecord
  belongs_to :tenant
  validates :account_id, presence: true, uniqueness: true
  validates :external_id, presence: true
  has_many :findings

  def create_random_external_id
    self.external_id = "#{Faker::Adjective.positive}-#{Faker::Appliance.equipment}".gsub(/\s+/, '-').downcase
  end
end
