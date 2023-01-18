class Step < ApplicationRecord
  belongs_to :scheduled_plan_execution
  belongs_to :resource_filter

  enum :direction, {
    up: "UP",
    down: "DOWN"
  }

  enum :status, {
    started: "STARTED",
    stopped: "STOPPED",
    failed: "FAILED"
  }

  def increment(attr)
    Step.where(id: self.id).update_all("#{attr} = #{attr} + 1")
    self.reload
  end
end
