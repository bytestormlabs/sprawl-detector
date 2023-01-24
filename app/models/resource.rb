class Resource < ApplicationRecord
  belongs_to :account
  belongs_to :scan, optional: true
  belongs_to :step, optional: true

  has_many :findings

  %i[region resource_type].each do |field|
    validates field, presence: true
  end

  validate :has_scan_or_step

  def has_scan_or_step
    if scan.nil? && step.nil?
      errors(:step, "Atleast one of step or scan needs to be supplied.")
    end
  end

  def create_finding(scan, issue_type, last_activity_date = nil)
    if last_activity_date
      self.last_activity_date = last_activity_date
      save
    end

    finding = Finding.create_with(status: :open).find_or_create_by!(
      resource: self,
      issue_type: issue_type,
      account: account,
      scan: scan
    )
    finding.scan = scan
    finding.save!
    finding
  end

  def last_used_before?(target_date)
    last_activity_date.nil? || last_activity_date < target_date
  end
end
