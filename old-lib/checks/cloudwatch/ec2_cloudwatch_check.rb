class Ec2CloudWatchCheck < CloudWatchCheck
  attr_accessor :matcher

  def initialize(opts = {})
    super(opts)
    @namespace = "AWS/EC2"
  end
end
