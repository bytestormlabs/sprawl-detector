class FindingSerializer < ActiveModel::Serializer
  attributes :id, :account
  attributes :message, :issue_type, :resource_id, :resource_type, :creation_date, :region, :status
  attributes :metadata

  def metadata
    object&.resource&.metadata
  end

  def creation_date
    return nil if object&.resource&.metadata.nil?
    hash = object&.resource&.metadata
    ["instance_create_time", "launch_time"].map do |key|
      hash[key]
    end.filter.first
  end

  def account
    {
      id: object&.resource&.account&.account_id,
      name: object&.resource&.account&.name
    }
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
