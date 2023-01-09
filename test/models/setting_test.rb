require "test_helper"

class SettingTest < ActiveSupport::TestCase
  class ValidationTests < SettingTest
    test "require name and value" do
      setting = Setting.new(account: Account.first, name: "name_of_field", data_type: :integer)
      assert !setting.valid?
    end
    test "alpha in integer setting fails validation" do
      setting = Setting.new(account: Account.first, data_type: :integer, name: "number_of_days", value: "abc")
      assert setting.invalid?
    end
    test "validation succeeds" do
      setting = Setting.new(account: Account.first, data_type: :integer, name: "number_of_days", value: "123")
      assert setting.valid?
    end
  end
end
