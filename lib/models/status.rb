class Status < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
  has_many :findings
end
