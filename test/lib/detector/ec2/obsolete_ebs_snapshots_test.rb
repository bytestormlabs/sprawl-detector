require "detector/ec2/obsolete_ebs_snapshots"
require "base_aws_integration_test"

class ObsoleteEbsSnapshotsTest < BaseAwsIntegrationTest
  detector = ObsoleteEbsSnapshots.new

  scan = Scan.create(account: Account.first, credentials: Aws::Credentials.new("abc", "1234"))

  test "create finding for snapshot" do
    before = Finding.count
    detector.execute(scan, "us-east-1")
    assert before + 1 == Finding.count
  end
end
