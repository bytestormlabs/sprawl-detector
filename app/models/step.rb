class Step < ApplicationRecord
  belongs_to :scheduled_plan_execution
  belongs_to :resource_filter
  has_many :resources

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
    Step.where(id: id).update_all("#{attr} = #{attr} + 1")
    reload
  end

  def add_resource(resource)
    self.metadata = (metadata || {"resources" => []})
    metadata["resources"].push(resource)
  end

  def resources
    metadata["resources"]
  end
end
