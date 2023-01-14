require "cost/cost_calculator"
require "base_aws_integration_test"

class CostCalculatorTest < BaseAwsIntegrationTest
  def decorator
    CostCalculator.new
  end

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
          }
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

  test "cost of ecr repository" do
    cost = decorator.decorate(Resource.new(
      region: "us-east-1",
      resource_type: "AWS::ECR::Repository",
      metadata: {
        "images" => [
          {
            "image_size_in_bytes" => 387686701
          },
          {
            "image_size_in_bytes" => 387686701
          },
          {
            "image_size_in_bytes" => 387686701
          },
          {
            "image_size_in_bytes" => 387686701
          },
          {
            "image_size_in_bytes" => 387686701
          }
        ]
      }
    ))
    assert_equal 0.19, cost
  end

  test "cost of classic load balancer" do
    cost = decorator.decorate(Resource.new(
      region: "us-east-1",
      resource_type: "AWS::ElasticLoadBalancing::LoadBalancer"
    ))
    assert_equal 18, cost
  end

  test "cost of elasticsearch cluster" do
    cost = decorator.decorate(Resource.new(
      region: "us-east-1",
      resource_type: "AWS::Elasticsearch::Domain",
      metadata: {
        elasticsearch_cluster_config: {
          instance_type: "t3.medium.search"
        }
      }
    ))
    puts "cost: #{cost}"
    assert_equal 52.56, cost
  end
end
