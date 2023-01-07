require "test_helper"

class FindingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers

  class AuthenticatedTests < FindingsControllerTest
    test "#index" do
      get findings_url, headers: {Authorization: "Bearer: abc-123-def-456"}
      assert_response 200
    end
  end

  class UnauthenticatedTests < FindingsControllerTest
    test "findings requires a signed in user" do
      get findings_url
      assert_response 401
    end
  end
end
