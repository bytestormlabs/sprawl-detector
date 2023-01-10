module Cloudwatch

  def check(namespace, metric)
    builder = RequestBuilder.new(namespace, metric)
  end

  # b = check("AWS/ACMPrivateCA", "Success").in_last(60).days
  # b.with_dimension("Operation", "IssueCertificate")
  # b.with_dimension("PrivateCAArn", resource.arn)
  # b.indicates_no_activity
  class RequestBuilder
    PERIOD_DAILY = (60*60*24)

    attr_accessor :request
    attr_accessor :region
    attr_accessor :number_of_days

    def initialize(namespace, metric)
      @region = region
      @number_of_days = 14
      @request = {
        namespace: namespace,
        metric_name: metric,
        statistics: ["Sum"],
        period: PERIOD_DAILY,
        start_time: (DateTime.now-@number_of_days).to_s,
        end_time: DateTime.now.to_s,
        dimensions: []
      }
    end

    def sum
      @request[:statistics] = ["Sum"]
      self
    end

    def average
      @request[:statistics] = ["Average"]
      self
    end

    def minimum
      @request[:statistics] = ["Minimum"]
      self
    end

    def maximum
      @request[:statistics] = ["Maximum"]
      self
    end

    def with_dimension(key, value)
      @request[:dimensions] << {
        name: key,
        value: value
      }
      self
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

    def has_expected_number_of_data_points?
      fetch_results if @results.nil?
      @results.datapoints.count >= @number_of_days
    end

    def indicates_zero_activity?
      fetch_results if @results.nil?
      @results.datapoints.empty? || @results.datapoints.map do |d|
        d[@request[:statistics].first.downcase.to_sym]
      end.sum == 0
    end

    def less_than?(number)
      fetch_results if @results.nil?
      @results.datapoints.empty? || @results.datapoints.all? do |d|
        d[@request[:statistics].first.downcase.to_sym] < number
      end
    end

    private
    def fetch_results
      params = {
        region: region
      }
      params[:credentials] = @credentials if @credentials
      client = Aws::CloudWatch::Client.new(params)
      @results = client.get_metric_statistics(@request)
    end
  end

end
