class Finding < ApplicationRecord
  belongs_to :status
  belongs_to :resolution, optional: true
  belongs_to :scan
  has_many :tags

  %i[category account_id resource_id issue_type region message scan].each do |field|
    validates field, presence: true
  end
end
