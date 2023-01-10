class AwsCostLineItem < ApplicationRecord
  scope :last_30_days, -> { where("date > ?", 30.days.ago) }
  belongs_to :account
end
