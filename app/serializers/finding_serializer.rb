class FindingSerializer < ActiveModel::Serializer
  attributes :id, :account
  attributes :message, :issue_type, :resource_id, :resource_type, :creation_date, :last_activity_date, :region, :status
  attributes :metadata
  attributes :estimated_cost

  def metadata
    object&.resource&.metadata
  end

  def creation_date
    object&.resource&.creation_date
  end

  def last_activity_date
    object&.resource&.last_activity_date
  end

  def estimated_cost
    object&.resource&.estimated_cost
  end

  def account
    object&.resource&.account&.name
  end

  def resource_id
    object&.resource&.resource_id
  end

  def region
    object&.resource&.region
  end

  def resource_type
    object&.resource&.resource_type
  end

  def message
    get_formatted_message(object)
  end

  private

  def get_formatted_message(object)
    params = {
      days: 90
    }
    if object.respond_to?(:parameters)
      params.merge!(object.parameters)
    end

    s = {
      "aws-ec2-ami-obsolete" => "Amazon machine image is older than {days} days.",
      "aws-ebs-snapshot-obsolete" => "Amazon EBS volumde is older than {days} days."
    }[object.issue_type]

    params.each do |key, value|
      s = s&.gsub("{#{key}}", value.to_s)
    end
    s
  end
end
