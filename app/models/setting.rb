class Setting < ApplicationRecord
  belongs_to :account

  enum :data_type, %i(integer string boolean)
  validates :name, presence: true
  validates :value, presence: true

  validate :data_type_matches_value

  def data_type_matches_value
    case data_type
    when "integer"
      errors.add(:value, "Value must be a number.") unless /\d+/ =~ value&.strip
    when "boolean"
      errors.add(:value, "Value must be either true or false.") unless ["true", "false"].include? value
    end
  end

  def self.create_int(prefix, name, description, value)
    Setting.new(name: [prefix, name].join('.'), description: description, value: value)
  end
end
