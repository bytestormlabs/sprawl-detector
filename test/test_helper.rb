ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "vcr"
require "authentication/token"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  VCR.configure do |config|
    config.cassette_library_dir = "test/fixtures/files/vcr_cassettes"
    config.hook_into :webmock
    config.filter_sensitive_data("SecretToken") do |interaction|
      interaction.request.headers["Authorization"]&.first
    end
    config.filter_sensitive_data("SecretAmzSecurityToken") do |interaction|
      interaction.request.headers["X-Amz-Security-Token"]&.first
    end
  end

  def signin_with_email(email)
    Token.create(email: email).to_base64
  end
end
