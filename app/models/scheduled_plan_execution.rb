class ScheduledPlanExecution < ApplicationRecord
  belongs_to :scheduled_plan
  has_many :steps

  enum :status, {
    started: "STARTED",
    stopped: "STOPPED",
    failed: "FAILED"
  }

  before_validation do |r|
    r.timestamp = DateTime.now if r.timestamp.nil?
    r.status = :started if r.status.nil?
  end
end
