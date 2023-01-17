class Filter < ActiveRecord::Base
  belongs_to :resource_filter
  validates :name, presence: true
  validates :value, presence: true
  validates :filter_type, presence: true, inclusion: {
    in: ["tag", "attribute"]
  }

  def is_tag_based?
    filter_type == "tag"
  end

  def to_filter
    key = is_tag_based? ? "tag:#{name}" : name
    {
      name: key,
      values: [value]
    }
  end
end
