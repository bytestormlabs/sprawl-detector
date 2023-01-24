class Scan < ApplicationRecord
  has_many :findings
  has_many :resources
  belongs_to :account

  attr_accessor :credentials

  enum :status, {
    started: "STARTED",
    failed: "FAILED",
    completed: "COMPLETED_SUCCESSFULLY"
  }

  def build_resource(region, resource_type, resource_id, resource)
    Resource.create_with(
      scan: self,
      metadata: resource.to_h
    ).find_or_create_by(
      account: account,
      resource_type: resource_type,
      resource_id: resource_id,
      region: region
    ).tap do |r|
      r.scan = self
      r.metadata = resource.to_h
      if resource&.to_h
        r.creation_date = [
          resource.to_h[:instance_create_time],
          resource.to_h[:launch_time],
          resource.to_h[:snapshot_create_time],
          resource.to_h[:start_time],
          resource.to_h[:creation_date],
          resource.to_h[:create_time],
          resource.to_h[:creation_timestamp],
          resource.to_h[:created_time],
          resource.to_h[:cache_cluster_create_time]
        ].find(&:itself)
      end
      r.save
    end
  end
end
