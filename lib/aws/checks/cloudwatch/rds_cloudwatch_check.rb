class RdsCloudWatchCheck < CloudWatchCheck
  attr_accessor :matcher

  def initialize(opts = {})
    super(opts)
    @namespace = "AWS/RDS"
  end
end
