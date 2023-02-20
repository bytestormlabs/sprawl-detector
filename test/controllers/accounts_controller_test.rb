require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  class AuthenticatedTests < AccountsControllerTest
    test "#index" do
      get accounts_url, headers: {Authorization: "Bearer: #{signin_with_email("frank@bytestormlabs.com")}"}
      assert_response 200
      assert_equal 1, JSON.parse(@response.body).count
    end

    test "create a new account with a new account id" do
      assert_difference "Account.count", 1 do
        post accounts_url, headers: {Authorization: "Bearer: #{signin_with_email("frank@bytestormlabs.com")}"}, params: {
          account: {
            account_id: "123412341234"
          }
        }
        assert_response 200
      end
    end

    test "reject account creation with a duplicate account id" do
      post accounts_url, headers: {Authorization: "Bearer: #{signin_with_email("frank@bytestormlabs.com")}"}, params: {
        account: {
          account_id: accounts(:test).account_id
        }
      }
      assert_response 400
    end
  end

  class UnauthenticatedTests < AccountsControllerTest
    test "#index" do
      get accounts_url
      assert_response 401
    end
  end
end
