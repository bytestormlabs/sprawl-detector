require "aws-sdk-cloudtrail"
require "aws_sdk_operations"

module Cloudtrail
  def resource_name(resource_name)
    RequestBuilder.new.resource_name(resource_name)
  end

  class RequestBuilder
    include AwsSdkOperations

    attr_accessor :request
    attr_accessor :region
    attr_accessor :number_of_days

    def initialize
      @region = region
      @number_of_days = 14
      @request = {
        lookup_attributes: [],
        start_time: (DateTime.now - @number_of_days).to_time.utc.to_datetime.to_s,
        end_time: DateTime.now.to_time.utc.to_datetime.to_s
      }
    end

    def lookup_attribute(key)
      existing = @request[:lookup_attributes].find do |lookup_attribute|
        lookup_attribute == key
      end
      if existing.nil?
        existing = {
          attribute_key: key
        }
        @request[:lookup_attributes] << existing
      end
      existing
    end

    def resource_name(resource_name)
      lookup_attribute("ResourceName")[:attribute_value] = resource_name.to_s
      self
    end

    def find(params = nil)
      results = []
      loop_until_finished(client, :lookup_events, @request) do |page|
        results = if block_given?
          results.concat(page.events.find_all do |event|
            yield(event)
          end)
        else
          results.concat(page.events)
        end
      end
      results
    end

    def first_event
      find.last
    end

    def in_last(n)
      @request[:start_time] = (DateTime.now - n).to_s
      @number_of_days = n
      self
    end

    def in(region)
      @region = region
      self
    end

    def with(credentials)
      @credentials = credentials
      self
    end

    def has_any?
      fetch_results if @results.nil?
      block_given? ? yield(@results.events) : @results.events.count > 0
    end

    private

    def client
      params = {
        region: region
      }
      params[:credentials] = @credentials if @credentials
      Aws::CloudTrail::Client.new(params)
    end
  end
end
