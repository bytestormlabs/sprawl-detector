class Resource < ApplicationRecord
  belongs_to :account
  belongs_to :scan
  has_many :findings
  %i[resource_id region scan account resource_type].each do |field|
    validates field, presence: true
  end
end
