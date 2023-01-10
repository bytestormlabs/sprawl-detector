require "test_helper"

class ScanTest < ActiveSupport::TestCase
  test "can be created and saved" do
    account = accounts(:test)
    scan = Scan.create(account: account, status: :started)
    assert scan.started?, "Scan should have started."
    scan.completed!
    assert scan.completed?, "Scan should be complete."
    scan.save
  end

  test "build resource" do
    account = accounts(:test)
    scan = Scan.create(account: account)

    resource = scan.build_resource("us-east-1", "AWS::EC2::Instance", "i-3fasdf23das", {
      instance_type: "m5.xlarge"
    })

    assert resource.scan == scan, "Should have set the scan instance to itself"
    assert resource.valid?, "Resource should be valid"
  end

  test "build resource doesn't duplicate resources on another scan" do
    account = accounts(:test)
    scan1 = Scan.create(account: account)

    resource1 = scan1.build_resource("us-east-1", "AWS::EC2::Instance", "i-3fasdf23das", {
      instance_type: "m5.xlarge"
    })
    resource1.save!

    # Let's find the same thing on another scan
    scan2 = Scan.create(account: account)
    resource2 = scan2.build_resource("us-east-1", "AWS::EC2::Instance", "i-3fasdf23das", {
      instance_type: "m5.xlarge"
    })
    resource2.save!
    assert resource1.id == resource2.id, "should not have created another resource."
  end
end
