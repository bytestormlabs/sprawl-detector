class Scan < ApplicationRecord
  has_many :findings
  belongs_to :account
  enum :status, {
    started: "STARTED",
    failed: "FAILED",
    completed: "COMPLETED_SUCCESSFULLY"
  }

  def build_resource(region, resource_type, resource_id, resource)
    Resource.create_with(
      scan: self
    ).find_or_create_by(
      account: self.account,
      resource_type: resource_type,
      resource_id: resource_id,
      region: region
    ).tap do |r|
      r.metadata = resource.to_h
    end
  end
end
