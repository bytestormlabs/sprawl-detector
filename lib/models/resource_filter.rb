# A domain class for recording metadata on how to target
# certain resources for scheduling.
class ResourceFilter < ActiveRecord::Base
  validates :name, presence: true
  validates :value, presence: true
  validates :filter_type, presence: true, inclusion: {
    in: ["tag", "attribute"]
  }
  belongs_to :scheduled_operation

  def is_tag_based?
    filter_type == "tag"
  end

  def to_filter
    puts "name, value: #{name}, #{value}"
    key = is_tag_based? ? "tag:#{name}" : name
    {
      name: key,
      values: [value]
    }
  end
end
