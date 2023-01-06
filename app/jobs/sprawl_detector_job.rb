require "scan_for_findings"

class SprawlDetectorJob < ApplicationJob
  queue_as :default

  def perform(*args)
    ctx = ScanContext.new(account_id: ENV.fetch("AWS_ACCOUNT_ID"))

    ScanForFindings.new.execute(ctx)
  end
end
