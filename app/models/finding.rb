class Finding < ApplicationRecord
  belongs_to :resolution, optional: true
  belongs_to :scan
  belongs_to :account
  belongs_to :resource

  attr_accessor :message

  enum :status, {
    open: "OPEN",
    closed: "CLOSED"
  }

  %i[issue_type scan account resource].each do |field|
    validates field, presence: true
  end
end
