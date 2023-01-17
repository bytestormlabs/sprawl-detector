class ScheduledPlan < ApplicationRecord
  belongs_to :account
  has_many :resource_filters, autosave: true

  validates :up_schedule, presence: true
  validates :down_schedule, presence: true

  validates_associated :resource_filters

  after_save do |scheduled_plan|
    # Upsert this as a job in the AWS Scheduler system
    UpsertSchedulerJob.perform_later(id)
  end

  after_update do |scheduled_plan|
    # Upsert this as a job in the AWS Scheduler system
    UpsertSchedulerJob.perform_later(id)
  end

  after_destroy do |scheduled_plan|
    # Delete this job in the AWS Scheduler system
    # DeleteSchedulerJob.perform_later(self)
  end

  before_validation do |scheduled_plan|
    if scheduled_plan.up_schedule.nil?
      scheduled_plan.up_schedule = "0 8 * * MON-FRI ?"
      scheduled_plan.down_schedule = "0 20 * * MON-FRI ?"
    end
  end
end
