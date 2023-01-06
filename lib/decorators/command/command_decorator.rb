class CommandDecorator

  def initialize
    load_configuration
  end

  def decorate(finding)
    action = @commands[:actions].find do |action|
      action[:issue_types].include?(finding.issue_type)
    end

    return if action.nil?

    action[:commands].map do |command|
      metadata = finding["metadata"]
      region = finding.region
      output = eval(command[:linux])

      return output
      # {
      #   title: command[:title],
      #   command: output
      # }
    end
  end

  def add_cluster_if_prudent(metadata)
    metadata["db_cluster_identifier"] ? "-cluster" : ""
  end

  def load_configuration
    file = File.join(File.dirname(__FILE__), "/commands.yaml")
    @commands = ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file(file))
  end
end
