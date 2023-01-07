require "test_helper"

class FindingsControllerTest < ActionDispatch::IntegrationTest
  class AuthenticatedTests < FindingsControllerTest
    test "#index" do
      get findings_url, headers: {Authorization: "Bearer: abc-123-def-456"}
      assert_response 200
      assert_equal 100, JSON.parse(@response.body)["data"].count
    end

    test "#index only shows logged in users findings" do
      skip "Not implemented yet."
      get findings_url, headers: {Authorization: "Bearer: abc-123-def-456"}
      assert_response 200
      assert_equal 100, JSON.parse(@response.body)["data"].count
    end
  end

  class UnauthenticatedTests < FindingsControllerTest
    test "findings requires a signed in user" do
      get findings_url
      assert_response 401
    end
  end
end
