require "test_helper"

class FindingsControllerTest < ActionDispatch::IntegrationTest
  class AuthenticatedTests < FindingsControllerTest
    test "show all findings" do
      get findings_url, headers: {Authorization: "Bearer: abc-123-def-456"}
      assert_response 200
      assert_equal 100, JSON.parse(@response.body)["data"].count

      get findings_url, headers: {Authorization: "Bearer: zzz-999-zzz-999"}
      assert_response 200
      assert_equal 20, JSON.parse(@response.body)["data"].count
    end

    test "filter by status" do
      get findings_url, params: {status: "closed"}, headers: {Authorization: "Bearer: abc-123-def-456"}
      assert_response 200
      assert_equal 20, JSON.parse(@response.body)["data"].count
    end
  end

  class UnauthenticatedTests < FindingsControllerTest
    test "findings requires a signed in user" do
      get findings_url
      assert_response 401
    end
  end
end
