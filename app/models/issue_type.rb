class IssueType < ApplicationRecord
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :description, presence: true
  validates :service, presence: true
  has_many :settings

  validates :category, inclusion: {
    in: ["Unused", "Outdated", "Configuration", "Under Utilized", "Infrequently Used"]
  }
end
