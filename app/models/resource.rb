class Resource < ApplicationRecord
  belongs_to :account
  belongs_to :scan
  has_many :findings
  %i[region scan account resource_type].each do |field|
    validates field, presence: true
  end

  def create_finding(issue_type)
    Finding.create_with(status: :open).find_or_create_by!(
      resource: self,
      issue_type: issue_type,
      account: account,
      scan: scan
    )
  end
end
