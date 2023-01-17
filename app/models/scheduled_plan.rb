class ScheduledPlan < ApplicationRecord
  belongs_to :account
  has_many :resource_filters
end
