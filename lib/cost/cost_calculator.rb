require "yaml"
require "aws-sdk-pricing"

class CostCalculator
  attr_accessor :descriptors, :logger, :cache, :client, :warnings

  def initialize
    pattern = "#{File.expand_path(__dir__)}/**/*.yaml"
    @descriptors = Dir.glob(pattern).map do |file|
      YAML.load_file(file)
    end
    @logger = Logger.new($stdout)
    @client = Aws::Pricing::Client.new(region: "us-east-1", credentials: Aws::SharedCredentials.new(profile_name: "default"))
    @cache = {}
    @warnings = []
  end

  def retrieve_from_cache(params)
    key = params.hash
    if !cache.has_key?(key)
      begin
        result = client.get_products(params)
        cache[key] = result
      rescue => e
        puts "Hit an issue processing #{params}"
        logger.error e
      end
    end
    cache.fetch(key)
  end

  def decorate(resource)
    descriptor = find_descriptor_by(resource.resource_type)
    if descriptor.nil?
      logger.warn "Unable to find cost descriptor for '#{resource.resource_type}'" if !warnings.include? resource.resource_type
      warnings << resource.resource_type
      return
    end

    return if descriptor.nil?

    if descriptor["cost"].present?
      return descriptor["cost"].to_d
    end

    result = retrieve_from_cache({
      service_code: descriptor["service"],
      filters: build_filters(resource, descriptor["filters"])
    }).price_list

    if result&.empty?
      logger.warn "Didn't find any results for #{build_filters(resource, descriptor["filters"])}"
      return
    end

    prices_per_unit = result.map do |r|
      collect_price_per_unit(r)
    end.filter.uniq

    price_per_unit = prices_per_unit.first

    if prices_per_unit.count != 1
      if descriptor["multiple_price_point_behavior"].present?
        price_per_unit = prices_per_unit.reject { |x| x <= 0.01 }.min
      else
        logger.error "Found #{prices_per_unit.count} different price points for #{resource.resource_type}"
        result.each do |r|
          logger.error JSON.pretty_generate(JSON.parse(r))
        end
        return nil
      end
    end

    calculate_price(descriptor["price_components"], price_per_unit, resource.metadata)
  end

  private

  def build_filters(resource, filters)
    metadata = resource["metadata"] # standard:disable Lint/UselessAssignment
    region = resource.region  # standard:disable Lint/UselessAssignment

    filters.map do |filter|
      unless filter["condition"].present? && eval(filter["condition"])
        value = filter["value"] || eval(filter["eval"])
        {
          type: "TERM_MATCH",
          field: filter["key"],
          value: value
        }
      end
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

    if terms["OnDemand"].nil?
      logger.warn "Didn't find OnDemand terms..."
      return nil
    end

    dimension = terms.values.first
    (_sku, terms) = dimension.first
    price_dimensions = terms["priceDimensions"]
    return if price_dimensions.size != 1
    units = price_dimensions.values.first
    units["pricePerUnit"]["USD"].to_d
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
      "redis" => "Redis",
      "memcached" => "memcached"
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
    {
      "aurora" => "Aurora",
      "aurora-mysql" => "Aurora MySQL",
      "aurora-postgresql" => "Aurora PostgreSQL",
      "custom-sqlserver-ee" => "Microsoft SQL Server Enterprise Edition for custom RDS",
      "custom-sqlserver-se" => "Microsoft SQL Server Standard Edition for custom RDS",
      "custom-sqlserver-web" => "Microsoft SQL Server Web Edition for custom RDS",
      "docdb" => "Amazon DocumentDB (with MongoDB compatibility)",
      "mariadb" => "MariaDB",
      "mysql" => "MySQL Community Edition",
      "neptune" => "neptune",
      "oracle-ee" => "Oracle",
      "oracle-ee-cdb" => "Oracle",
      "oracle-se2" => "Oracle",
      "oracle-se2-cdb" => "Oracle",
      "postgres" => "PostgreSQL",
      "sqlserver-ee" => "SQL Server",
      "sqlserver-ex" => "SQL Server",
      "sqlserver-se" => "SQL Server",
      "sqlserver-web" => "SQL Server"
    }[engine_code]
  end

  def translate_edition(engine_code)
    puts "entering translate_edition(engine_code = #{engine_code})"
    {
      "sqlserver-ee" => "Enterprise",
      "sqlserver-se" => "Standard",
      "sqlserver-ex" => "Express",
      "sqlserver-web" => "Web"
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
