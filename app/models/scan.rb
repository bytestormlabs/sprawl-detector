require "detector/support/cloudtrail"

class Scan < ApplicationRecord
  include Cloudtrail
  has_many :findings
  has_many :resources
  belongs_to :account

  attr_accessor :credentials, :skip_audit_logging

  def initialize(*args)
    super
    @skip_audit_logging = true
  end

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

      # Try to find the creation date...
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

      unless skip_audit_logging
        if r.creation_date && r.creation_date > 90.days.ago && credentials && r.created_by.nil?

          unless [
            "AWS::EC2::Volume",
            "AWS::EC2::Ami",
            "AWS::EBS::Snapshot"
          ].include?(r.resource_type)
            # Try to find the Cloudtrail fields
            event = resource_name(r.resource_id).in(r.region).find.last
            # TODO: Check for 'create' events?
            if event&.event_name&.start_with?("Create")
              r.created_by = event.username
              r.created_on = event.event_time.to_s
              r.event_id = event.event_id
            end
          end
        end
      end
      r.save
    end
  end
end
