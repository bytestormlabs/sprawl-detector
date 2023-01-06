class Resolution < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  has_many :findings
end
