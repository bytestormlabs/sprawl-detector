class Profile < ApplicationRecord
  belongs_to :account
  belongs_to :tenant

  has_many :settings
end
