class FindingSerializer < ActiveModel::Serializer
  attributes :id, :account_id, :message, :issue_type, :resource_id, :resource_type, :region, :status

  def account_id
    object&.resource&.account&.account_id
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
