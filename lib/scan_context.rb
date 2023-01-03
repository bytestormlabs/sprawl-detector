class ScanContext
  attr_accessor :aws_account_id, :tenant_id, :scan

  def initialize(opts = {})
    @aws_account_id = opts.fetch(:account_id)
    # @tenant_id = opts.fetch(:tenant_id)
    @logger = Logger.new($stdout)
    @logger.level = Logger::DEBUG
    @logger.formatter = proc do |severity, datetime, progname, msg|
      date_format = datetime.strftime("%Y-%m-%d %H:%M:%S")
      "[#{date_format}] #{severity} [account_id: #{aws_account_id}]\t #{msg}\n"
    end
  end

  attr_reader :logger
end
