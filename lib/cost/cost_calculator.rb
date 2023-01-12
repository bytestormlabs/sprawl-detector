require "yaml"
require "aws-sdk-pricing"

class CostCalculator
  attr_accessor :descriptors, :logger, :cache, :client

  def initialize
    pattern = "#{File.expand_path(__dir__)}/**/*.yaml"
    @descriptors = Dir.glob(pattern).map do |file|
      YAML.load_file(file)
    end
    @logger = Logger.new($stdout)
    @client = Aws::Pricing::Client.new(region: "us-east-1")
    @cache = {}
  end

  def retrieve_from_cache(params)
    key = params.hash
    if !cache.has_key?(key)
      begin
        result = client.get_products(params)
        cache[key] = result
      rescue => e
        puts "Hit an issue processing #{params}"
      end
    end
    cache.fetch(key)
  end

  def decorate(resource)
    descriptor = find_descriptor_by(resource.resource_type)
    # raise "No descriptors found for #{resource.resource_type}" if descriptor.nil?
    return if descriptor.nil?

    result = retrieve_from_cache({
      service_code: descriptor["service"],
      filters: build_filters(resource, descriptor["filters"])
    }).price_list

    return if result&.empty?

    prices_per_unit = result.map do |r|
      collect_price_per_unit(r)
    end.filter.uniq

    if (prices_per_unit.count != 1)
      logger.error "Found #{prices_per_unit.count} different price points..."
      pp result
      return nil
    end

    calculate_price(descriptor["price_components"], prices_per_unit.first, resource.metadata)
  end

  private
  def build_filters(resource, filters)
    metadata = resource["metadata"]
    region = resource.region

    filters.map do |filter|
      value = filter["value"] || eval(filter["eval"])
      {
        type: "TERM_MATCH",
        field: filter["key"],
        value: value
      }
    end
  end

  def find_descriptor_by(resource_type)
    @descriptors.find do |descriptor|
      descriptor["resource_type"] == resource_type
    end
  end

  def collect_price_per_unit(result)
    price_component = JSON.parse(result)
    terms = price_component["terms"]

    return nil if terms["OnDemand"].nil?

    dimension = terms.values.first
    (sku, terms) = dimension.first
    price_dimensions = terms["priceDimensions"]
    return if price_dimensions.size != 1
    units = price_dimensions.values.first
    price_per_unit = units["pricePerUnit"]["USD"].to_d
  end

  def calculate_price(price_components, price_per_unit, metadata)
    price = price_components.map do |component|
      multiplicand = eval(component)
      multiplicand.to_d
    end.inject(:*)

    price.ceil(2)
  end

  def translate_cache_engine(engine)
    {
      "redis" => "Redis"
    }[engine]
  end

  def translate_load_balancer_family(type)
    {
      "application" => "Load Balancer-Application",
      "network" => "Load Balancer-Network",
      "gateway" => "Load Balancer-Gateway"
    }[type]
  end

  def translate_engine(engine_code)
    puts "entering translate_engine(engine_code = #{engine_code})"
    {
      "aurora" => "Aurora",
      "aurora-mysql" => "Aurora MySQL",
      "aurora-postgresql" => "Aurora (PostgreSQL)",
      "custom-sqlserver-ee" => "Microsoft SQL Server Enterprise Edition for custom RDS",
      "custom-sqlserver-se" => "Microsoft SQL Server Standard Edition for custom RDS",
      "custom-sqlserver-web" => "Microsoft SQL Server Web Edition for custom RDS",
      "docdb" => "Amazon DocumentDB (with MongoDB compatibility)",
      "mariadb" => "MariaDb Community Edition",
      "mysql" => "MySQL Community Edition",
      "neptune" => "neptune",
      "oracle-ee" => "Oracle Database Enterprise Edition",
      "oracle-ee-cdb" => "Oracle Database Enterprise Edition (CDB)",
      "oracle-se2" => "Oracle Database Standard Edition Two",
      "oracle-se2-cdb" => "Oracle Database Standard Edition Two (CDB)",
      "postgres" => "PostgreSQL",
      "sqlserver-ee" => "MicrosoftSQLServerEnterpriseEdition",
      "sqlserver-ex" => "Microsoft SQLServer Express Edition",
      "sqlserver-se" => "MicrosoftSQLServer Standard Edition",
      "sqlserver-web" => "MicrosoftSQL Server Web Edition"
    }[engine_code]
  end

  def transfer_region_prefix(region)
    {
      "us-east-1" => "USE1-",
      "us-east-2" => "USE2-",
      "us-west-1" => "USW1-",
      "us-west-2" => "USW2-",
      "eu-west-1" => "EU-",
      "eu-west-2" => "EUW2-",
      "eu-west-3" => "EUW3-"
    }[region]
  end

  def region_prefix(region)
    {
      "us-east-1" => "",
      "us-east-2" => "USE2-",
      "us-west-1" => "USW1-",
      "us-west-2" => "USW2-",
      "eu-west-1" => "EU-",
      "eu-west-2" => "EUW2-",
      "eu-west-3" => "EUW3-"
    }[region]
  end
end
