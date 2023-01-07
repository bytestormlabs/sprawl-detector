class Account < ApplicationRecord
  belongs_to :tenant
  validates :account_id, presence: true, uniqueness: true
  has_many :findings
end
