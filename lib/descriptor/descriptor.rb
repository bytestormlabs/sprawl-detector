require "yaml"

class Descriptor
  attr_accessor :descriptors, :cache

  def initialize
    pattern = "#{File.expand_path(__dir__)}/**/*.yaml"
    @descriptors = Dir.glob(pattern).map do |file|
      YAML.load_file(file)
    end
    @cache = {}
  end

  def decorate(finding)
    descriptors.find do |descriptor|
      descriptor["issue_type"] == finding.issue_type
    end
  end
end
