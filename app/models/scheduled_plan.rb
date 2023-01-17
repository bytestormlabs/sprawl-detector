class ScheduledPlan < ApplicationRecord
  belongs_to :account
  has_many :resource_filters

  validates :up_schedule, presence: true
  validates :down_schedule, presence: true

  after_save do |scheduled_plan|
    # Upsert this as a job in the AWS Scheduler system
  end

  after_update do |scheduled_plan|
    # Upsert this as a job in the AWS Scheduler system
  end

  after_destroy do |scheduled_plan|
    # Delete this job in the AWS Scheduler system
  end
end
