require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "don't allow duplicate signups" do
    post user_registration_url, params: {
      user: {
        email: "frank@bytestormlabs.com",
        password: "12341234",
        name: "Frank Lamantia"
      },
      tenant: {name: "ByteStorm Labs"}
    }, as: :json
    assert_response 409
  end

  test "ensure a new tenant is created upon signup" do
    assert_difference "Tenant.count", 1 do
      post user_registration_url, params: {
        user: {
          email: "john@bytestormlabs.com",
          password: "12341234",
          name: "Johnny Cage"
        },
        tenant: {
          name: "ByteStorm Labs"
        }
      }, as: :json
      assert_response 200
    end
  end
end
