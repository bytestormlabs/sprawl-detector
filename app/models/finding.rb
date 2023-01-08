class Finding < ApplicationRecord
  belongs_to :status
  belongs_to :resolution, optional: true
  belongs_to :scan
  belongs_to :account
  belongs_to :resource

  %i[category issue_type message scan].each do |field|
    validates field, presence: true
  end
end
