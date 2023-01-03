class Command
  def each_region
    [
      "us-east-1", "us-east-2", "us-west-1", "us-west-2", "eu-west-1", "eu-west-2", "eu-west-3"
    ].map do |region|
      yield(region)
    end
  end
end
