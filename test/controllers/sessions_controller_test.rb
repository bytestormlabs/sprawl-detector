require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers

  test "don't allow login for a bad password" do
    post user_session_url, params: {
      user: {
        email: "frank@bytestormlabs.com",
        password: "12341234"
      }
    }, as: :json
    assert_response 401
  end

  test "allow login" do
    post user_session_url, params: {
      user: {
        email: "frank@bytestormlabs.com",
        password: "hello123"
      }
    }, as: :json
    assert_response 200
  end
end
