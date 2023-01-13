class TagDecorator
  def decorate(finding)
    # See if there is a Cloudformation stack attached

    tags = (finding.metadata["tags"] || finding.metadata["tags_list"] || [])

    has_cloudformation_tag = tags.any? do |tag|
      tag["name"] == "aws:cloudformation:stack-name"
    end

    if has_cloudformation_tag
      finding.tags.push("CloudFormation")
    end
  end
end
