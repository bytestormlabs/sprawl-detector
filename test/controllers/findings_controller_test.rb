require "test_helper"

class FindingsControllerTest < ActionDispatch::IntegrationTest
  class AuthenticatedTests < FindingsControllerTest
    test "show all findings" do
      skip "Need to figure out nested fixtures..."
      params = {
        region: "us-east-1",
        account: accounts(:test).account_id,
        issue_type: "aws-ec2-ebs-volume-unused"
      }
      get findings_url, params: params, headers: {Authorization: signin_with_email("frank@bytestormlabs.com")}
      assert_response 200
      puts @response.body
      assert_equal 100, JSON.parse(@response.body)["data"].count

      # get findings_url, headers: {Authorization: signin_with_email("johnny.cage@acmeinc.com")}
      # assert_response 200
      # assert_equal 20, JSON.parse(@response.body)["data"].count
    end

    test "filter by status" do
      skip "Broken until integration is done"
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
