require 'minitest/around/unit'
require "aws-sdk-sts"

class BaseAwsIntegrationTest < ActiveSupport::TestCase
  def around
    VCR.use_cassette("#{self.class.name}_#{@test_name}", update_content_length_header: true, erb: true) do
      yield
    end
  end
  def initialize(name = nil)
    @test_name = name.gsub(/\s+/, '_').gsub(/[^a-zA-Z0-9_-]/, '')
    super(name) unless name.nil?
  end
end
