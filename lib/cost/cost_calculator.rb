require "yaml"
require "aws-sdk-pricing"

class CostCalculator
  attr_accessor :descriptors, :logger

  def initialize
    pattern = "#{File.expand_path(__dir__)}/**/*.yaml"
    @descriptors = Dir.glob(pattern).map do |file|
      YAML.load_file(file)
    end
    @logger = Logger.new($stdout)
  end

  def decorate(resource)
    descriptor = find_descriptor_by(resource.resource_type)
    return if descriptor.nil?

    client = Aws::Pricing::Client.new(region: "us-east-1")

    result = client.get_products({
      service_code: descriptor["service"],
      filters: build_filters(resource, descriptor["filters"])
    }).price_list

    return if result&.empty?

    prices_per_unit = result.map do |r|
      collect_price_per_unit(r)
    end.filter.uniq

    if (prices_per_unit.count > 1)
      logger.error "Found #{prices_per_unit.count} different price points..."
      logger.error prices_per_unit.join(", ")
      return nil
    end

    calculate_price(descriptor["price_components"], prices_per_unit.first, resource.metadata)
  end

  private
  def build_filters(resource, filters)
    metadata = resource["metadata"]
    region = resource.region
    result = [
      # {
      #   type: "TERM_MATCH",
      #   field: "version",
      #   value: "Current"
      # }
    ]

    filters.each do |filter|
      value = filter["value"] || eval(filter["eval"])
      result << {
        type: "TERM_MATCH",
        field: filter["key"],
        value: value
      }
    end
    result
  end

  def translate_load_balancer_family(type)
    {
      "application" => "Load Balancer-Application",
      "network" => "Load Balancer-Network",
      "gateway" => "Load Balancer-Gateway"
    }[type]
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
end
