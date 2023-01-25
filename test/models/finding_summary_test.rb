require "test_helper"

class FindingSummaryTest < ActiveSupport::TestCase
  fixtures :tenants, :findings, :accounts
  test "the truth" do
    FindingSummary.find_by_tenant(tenants(:bytestormlabs).id)
  end
end
