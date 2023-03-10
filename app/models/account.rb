require "faker"

class Account < ApplicationRecord
  belongs_to :tenant
  validates :account_id, presence: true
  validates :external_id, presence: true
  has_many :findings
  has_many :scans
  has_many :settings
  has_many :resources
  has_many :scheduled_plans
  
  before_validation do |a|
    a.create_random_external_id if a.external_id.nil?
  end

  def create_random_external_id
    self.external_id = "#{Faker::Adjective.positive}-#{Faker::Appliance.equipment}".gsub(/\s+/, "-").downcase
  end
end
