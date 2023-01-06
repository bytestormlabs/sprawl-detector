require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "find user by email" do
    assert !User.find_by_email("frank@bytestormlabs.com").nil?
    assert !User.find_by_email("frank@bytestormlabs.com").tenant.nil?
  end
end
