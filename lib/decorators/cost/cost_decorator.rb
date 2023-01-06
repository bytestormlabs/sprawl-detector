require "active_support/core_ext/hash/indifferent_access"
require "aws-sdk-pricing"
require "yaml"

class CostDecorator

  def initialize
    load_configuration
    @cache = {}
  end

  def fetch_or_set(params)
    result = nil
    if @cache.has_key?(params.hash)
      result = @cache.fetch(params.hash)
    else
      puts "entering get_products #{params}"
      result = yield(params)
      @cache[params.hash] = result
      pp result
    end
    result
  end

  def decorate(finding)
    if (finding.issue_type == "aws-route53resolver-endpoint-unused")
      # Why did this break!?
      return 0.125 * finding.metadata["ip_address_count"] * 720.0
    end
    offer_code_configuration = @configuration[:offer_codes].find do |offer_code_configuration|
      offer_code_configuration[:issue_types].include?(finding.issue_type)
    end

    return if offer_code_configuration.nil?

    constant_price = offer_code_configuration["constant_price"]
    return constant_price.to_d if constant_price

    client = Aws::Pricing::Client.new(region: "us-east-1")

    params = {
      service_code: offer_code_configuration[:service_code],
      filters: create_filters(finding, offer_code_configuration)
    }

    price_list = fetch_or_set(params) { |params|
      puts
        ["aws pricing get-products --service-code ",
          params[:service_code],
          " --filters ",
          params[:filters].map { |f| "Type=TERM_MATCH,Field=#{f[:field]},Value=#{f[:value]}" },
          " --region us-east-1" ].join("")
      result = nil
      begin
        result = client.get_products(params).price_list
      rescue
      end
      result
    }

    price_list&.each do |p|
      puts "> #{JSON.pretty_generate(JSON.parse(p))}"
      puts ""
    end

    # raise "Adfafaf"

    # puts "Found #{price_list.size} prices."

    return if price_list.nil? || price_list&.size < 1

    price_component = JSON.parse(price_list.first)

    terms = price_component["terms"]
    puts "Found #{terms.size} price terms."

    return if terms["OnDemand"].nil?

    dimension = terms.values.first

    sku, terms = dimension.first

    price_dimensions = terms["priceDimensions"]
    # puts "Found #{price_dimensions.size} price dimensions."

    return if price_dimensions.size != 1

    # pp price_dimensions

    units = price_dimensions.values.first
    price_per_unit = units["pricePerUnit"]["USD"].to_d

    # puts "Found #{price_per_unit} for price_per_unit"
    price = offer_code_configuration[:price_components].map do |component|
      metadata = finding.metadata
      multiplicand = eval(component)
      puts "Found #{multiplicand} for #{component}"
      multiplicand.to_d
    end.inject(:*)

    price.ceil(2)
  end

  def create_filters(finding, offer_code_configuration)
    metadata = finding["metadata"]
    region = finding.region

    offer_code_configuration[:filters].map do |filter|
      value = filter[:value] || eval(filter[:eval])
      # puts "\"#{filter[:key]}\": #{value}"
      {
        type: "TERM_MATCH",
        field: filter[:key],
        value: value
      }
    end
  end

  def load_configuration
    file = File.join(File.dirname(__FILE__), "/cost_decorator.yaml")
    @configuration = ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file(file))
  end

  # def ebs_usage_type(region)
  #   {
  #     "us-east-1" => "EBS:SnapshotUsage",
  #     "us-east-2" => "USE2-EBS:SnapshotUsage",
  #     "us-west-1" => "USW1-EBS:SnapshotUsage",
  #     "us-west-2" => "USW2-EBS:SnapshotUsage",
  #     "eu-west-1" => "EUW1-EBS:SnapshotUsage",
  #     "eu-west-2" => "EUW2-EBS:SnapshotUsage",
  #     "eu-west-3" => "EUW3-EBS:SnapshotUsage"
  #   }[region]
  # end

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

  def translate_engine(engine_code)
    # puts "entering translate_engine(engine_code = #{engine_code})"
    {
      "aurora-mysql" => "Aurora MySQL",
      "aurora-postgresql" => "Aurora PostgreSQL"
    }[engine_code]
  end

  def translate_load_balancer_family(type)
    {
      "application" => "Load Balancer-Application",
      "network" => "Load Balancer-Network",
      "gateway" => "Load Balancer-Gateway"
    }[type]
  end

  def translate_cache_engine(engine)
    {
      "redis" => "Redis"
    }[engine]
  end

  def remove_prefix(prefix, string)
    string.gsub(prefix, "")
  end

  def get_availability_zone_type(is_multi_az)
    puts "entering get_availability_zone_type(is_multi_az = #{is_multi_az})"
    is_multi_az ? "Multiple" : "Single"
  end
end
