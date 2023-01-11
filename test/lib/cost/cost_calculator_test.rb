require "cost/cost_calculator"
require "base_aws_integration_test"

class CostCalculatorTest < BaseAwsIntegrationTest
  decorator = CostCalculator.new

  test "get application load balancer price" do
    cost = decorator.decorate(Resource.new(
      region: "us-east-1",
      resource_type: "AWS::ElasticLoadBalancingV2::LoadBalancer",
      metadata: {
        "type" => "application",
        "availability_zones" => [
          {
            "subnet_id" => "subnet-1234"
          },
          {
            "subnet_id" => "subnet-5678"
          },
        ]
      }
    ))
    assert_equal 16.2, cost
  end

  test "get cloudwatch log group pricing" do
    cost = decorator.decorate(Resource.new(
      region: "us-east-1",
      resource_type: "AWS::Logs::LogGroup",
      metadata: {
        "stored_bytes" => 53687091200
      }
    ))
    assert_equal 1.5, cost
  end

  test "get redshift managed backup price" do
    cost = decorator.decorate(Resource.new(
      region: "us-east-1",
      resource_type: "AWS::Redshift::RMSBackup",
      metadata: {
        "total_backup_size_in_mega_bytes" => 53687
      }
    ))
    assert_equal 1.26, cost
  end
end
