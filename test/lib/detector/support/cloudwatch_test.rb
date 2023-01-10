require "detector/support/cloudwatch"

class CloudwatchTest < BaseAwsIntegrationTest
  include Cloudwatch

  test "doesn't indicate zero_activity when there arent enough datapoints" do
    check = check("AWS/RDS", "Queries")
      .with_dimension("DBInstanceIdentifier", "byte-storm-labs-test-database-mysql-dbinstance-a7m8ktttcki8")
      .in("us-east-1")
      .with(Aws::Credentials.new("abc", "123"))
    assert check.indicates_zero_activity? == false, "There aren't enough datapoints to conclude there is zero activity"
  end

  test "correctly indicates zero activity when there are enough datapoints" do
    check = check("AWS/RDS", "Queries")
      .with_dimension("DBInstanceIdentifier", "byte-storm-labs-test-database-mysql-dbinstance-eke8ouwvjk1c")
      .in("us-east-1")
      .with(Aws::Credentials.new("abc", "123"))
    assert check.indicates_zero_activity?
  end
end
